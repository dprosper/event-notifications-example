data "ibm_resource_group" "group" {
  name = var.ibmcloud_resource_group
}
data "ibm_iam_auth_token" "tokendata" {}

resource "ibm_resource_instance" "event_notifications" {
  name              = "${var.resources_prefix}-event-notifications"
  service           = "event-notifications"
  plan              = "lite"
  location          = var.ibmcloud_region
  resource_group_id = data.ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

resource "ibm_resource_key" "resourceKey" {
  name                 = "${var.resources_prefix}-credential"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.event_notifications.id

  timeouts {
    create = "15m"
    delete = "15m"
  }
}

resource "ibm_en_source" "source" {
  instance_guid = ibm_resource_instance.event_notifications.guid
  name          = "${var.resources_prefix}-source"
  description   = "Source for Event Notifications destinations"
  enabled       = true
}

resource "ibm_en_topic" "topic" {
  instance_guid = ibm_resource_instance.event_notifications.guid
  name          = "${var.resources_prefix}-topic"
  description   = "Topic for Event Notifications events routing"

  sources {
    id = ibm_en_source.source.source_id

    rules {
      enabled           = true
      event_type_filter = "$.*"
    }
  }
}

data "http" "en_sources" {
  url = "https://${var.ibmcloud_region}.event-notifications.cloud.ibm.com/event-notifications/v1/instances/${ibm_resource_instance.event_notifications.guid}/sources"
  request_headers = {
    Authorization = data.ibm_iam_auth_token.tokendata.iam_access_token
  }
}

locals {
  resource_lifecycle_events_crn = [for source in jsondecode(data.http.en_sources.response_body).sources : source if source.type == "resource-lifecycle-events"].0.id
}

resource "ibm_en_topic" "lifecycle_topic" {
  instance_guid = ibm_resource_instance.event_notifications.guid
  name          = "resource-lifecycle-topic"
  description   = "Lifecycle Topic for Event Notifications events routing"

  sources {
    id = local.resource_lifecycle_events_crn

    rules {
      enabled           = true
      event_type_filter = "$.type == 'com.ibm.cloud.resource-lifecycle-events.instance:delete'"
    }
    rules {
      enabled           = true
      event_type_filter = "$.type == 'com.ibm.cloud.resource-lifecycle-events.instance:create'"
    }
  }
}

data "ibm_en_destinations" "lifecycle_destination_sms" {
  instance_guid = ibm_resource_instance.event_notifications.guid
  search_key    = "sms_ibm"
}

resource "ibm_en_subscription_sms" "lifecycle_subscription_sms" {
  instance_guid  = ibm_resource_instance.event_notifications.guid
  name           = "lifecycle-events-sms-subscription"
  description    = "Lifecycle Events Subscription for SMS destination"
  destination_id = data.ibm_en_destinations.lifecycle_destination_sms.destinations.0.id
  topic_id       = ibm_en_topic.lifecycle_topic.topic_id
  attributes {
    invited = [var.sms_phone_number]
  }
}

data "ibm_en_destinations" "lifecycle_destination_email" {
  instance_guid = ibm_resource_instance.event_notifications.guid
  search_key    = "smtp_ibm"
}

resource "ibm_en_subscription_email" "lifecycle_subscription_email" {
  instance_guid  = ibm_resource_instance.event_notifications.guid
  name           = "lifecycle-events-email-subscription"
  description    = "Lifecycle Events Subscription for Email destination"
  destination_id = data.ibm_en_destinations.lifecycle_destination_email.destinations.0.id
  topic_id       = ibm_en_topic.lifecycle_topic.topic_id

  attributes {
    add_notification_payload = true
    reply_to_mail            = var.reply_to_email
    reply_to_name            = var.reply_to_name
    from_name                = "${var.reply_to_name} on IBM Cloud"
    invited                  = [var.send_to_email]
  }
}

module "enable_lifecycle_events_helper" {
  source = "./modules/enable-lifecycle-events-helper"

  ibmcloud_iam_access_token              = data.ibm_iam_auth_token.tokendata.iam_access_token
  ibmcloud_event_notifications_guid      = ibm_resource_instance.event_notifications.guid
  ibmcloud_region                        = var.ibmcloud_region
  ibmcloud_resource_lifecycle_events_crn = local.resource_lifecycle_events_crn
}

resource "ibm_resource_instance" "cos" {
  name              = "${var.resources_prefix}-cos"
  resource_group_id = data.ibm_resource_group.group.id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
}

resource "ibm_iam_authorization_policy" "cos_policy" {
  source_service_name         = "event-notifications"
  source_resource_instance_id = ibm_resource_instance.event_notifications.guid
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = ibm_resource_instance.cos.guid
  roles                       = ["Reader", "Object Writer"]
}

resource "ibm_cos_bucket" "notifications_failures_bucket" {
  depends_on = [
    ibm_iam_authorization_policy.cos_policy
  ]

  bucket_name          = "${var.resources_prefix}-notifications-failures-bucket"
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = var.ibmcloud_region
  storage_class        = "smart"

  expire_rule {
    days   = 7
    enable = true
  }
}

resource "ibm_cos_bucket" "api_notifications_bucket" {
  depends_on = [
    ibm_iam_authorization_policy.cos_policy
  ]

  bucket_name          = "${var.resources_prefix}-api-notifications-bucket"
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = var.ibmcloud_region
  storage_class        = "smart"

  expire_rule {
    days   = 7
    enable = true
  }
}

resource "ibm_en_destination_cos" "cos_en_destination" {
  instance_guid = ibm_resource_instance.event_notifications.guid
  name          = "app-events-cos-destrination"
  type          = "ibmcos"
  description   = "IBM Cloud Object Storage Destination for event notification"
  config {
    params {
      bucket_name = ibm_cos_bucket.api_notifications_bucket.bucket_name
      instance_id = ibm_resource_instance.cos.resource_id
      endpoint    = "https://${ibm_cos_bucket.api_notifications_bucket.s3_endpoint_private}"
    }
  }
}

resource "ibm_en_subscription_cos" "cos_subscription" {
  instance_guid    = ibm_resource_instance.event_notifications.guid
  name             = "app-events-cos-subscription"
  description      = "IBM Cloud Object Storage subscription for Event Notification"
  destination_id   = ibm_en_destination_cos.cos_en_destination.destination_id
  topic_id         = ibm_en_topic.topic.topic_id
}

resource "local_file" "apply_output_env" {
    content  = <<EOT
instance_location=${ibm_resource_instance.event_notifications.location}
instance_guid=${ibm_resource_instance.event_notifications.guid}
api_key=${ibm_resource_key.resourceKey.credentials.apikey}
api_source_name=${ibm_en_source.source.name}
api_source_id=${ibm_en_source.source.source_id}
    EOT

    filename = ".apply.output.env"
}