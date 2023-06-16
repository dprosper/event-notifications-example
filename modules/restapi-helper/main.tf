provider "restapi" {
  alias                = "event_notifications_api_sources"
  uri                  = "https://${var.ibmcloud_region}.event-notifications.cloud.ibm.com/event-notifications/v1/instances"
  debug                = true
  write_returns_object = true

  headers = {
    Authorization  = var.ibmcloud_iam_access_token
    "Content-Type" = "application/json"
  }

  create_method  = "PATCH"
  update_method  = "PATCH"
  destroy_method = "PATCH"
}

resource "restapi_object" "lifecycle_events_enable" {
  provider = restapi.event_notifications_api_sources
  path     = "/${var.ibmcloud_event_notifications_guid}/sources/${var.ibmcloud_resource_lifecycle_events_crn}"
  data     = "{ \"enabled\": true }"
}