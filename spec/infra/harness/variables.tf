variable "region" {}

variable "component" {}
variable "deployment_identifier" {}

variable "service_name" {}
variable "service_port" {}

variable "domain_name" {}
variable "public_zone_id" {}
variable "private_zone_id" {}

variable "health_check_target" {}

variable "allow_cidrs" {
  type = "list"
}
variable "egress_cidrs" {
  type = "list"
}

variable "include_public_dns_record" {}
variable "include_private_dns_record" {}

variable "expose_to_public_internet" {}

variable "access_logs_bucket" {}
variable "access_logs_bucket_prefix" {}
variable "access_logs_interval" {}

variable "store_access_logs" {}
