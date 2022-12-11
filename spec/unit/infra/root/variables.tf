variable "region" {}

variable "component" {}
variable "deployment_identifier" {}

variable "service_name" {}
variable "service_port" {}

variable "domain_name" {}
variable "public_zone_id" {}
variable "private_zone_id" {}

variable "health_check_target" {
  default = null
}

variable "allow_cidrs" {
  type = list(string)
}
variable "egress_cidrs" {
  type    = list(string)
  default = null
}

variable "include_public_dns_record" {
  default = null
}
variable "include_private_dns_record" {
  default = null
}

variable "expose_to_public_internet" {
  default = null
}

variable "access_logs_bucket" {
  default = null
}
variable "access_logs_bucket_prefix" {
  default = null
}
variable "access_logs_interval" {
  default = null
}

variable "store_access_logs" {
  default = null
}
