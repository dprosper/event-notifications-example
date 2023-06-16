variable "ibmcloud_api_key" {
  description = "You IAM based API key."
}

variable "ibmcloud_region" {
  description = "The region to deploy the resources created by this template."
  default     = "us-south"
}

variable "ibmcloud_resource_group" {
  description = "The resource group for all the resources created."
  default     = "default"
}

variable "resources_prefix" {
  description = "Prefix is added to all resources that are created by this template."
}

variable "reply_to_email" {
  description = "email adddress to reply to."
}

variable "reply_to_name" {
  description = "name from where messages are sent from."
}

variable "send_to_email" {
  description = "email adddress to invite to receive email notifications."
}

variable "sms_phone_number" {
  description = "Phone to invite to receive SMS notifications."
}