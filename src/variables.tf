variable "region" {}
variable "vpc_id" {}
variable "subnet_ids" {
  type = "list"
}

variable "component" {}
variable "deployment_identifier" {}

variable "service_name" {}
variable "service_port" {}
variable "service_certificate_arn" {}

variable "domain_name" {}
variable "public_zone_id" {}
variable "private_zone_id" {}

variable "health_check_target" {
  default = "HTTP:80/health"
}
variable "allow_cidrs" {
  type = "list"
}

variable "egress_cidrs" {
  type = "list"
  default = []
}

variable "include_public_dns_record" {
  default = "no"
}
variable "include_private_dns_record" {
  default = "yes"
}

variable "expose_to_public_internet" {
  default = "no"
}