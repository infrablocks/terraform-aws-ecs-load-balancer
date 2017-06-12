variable "region" {}
variable "vpc_id" {}
variable "public_subnet_ids" {}
variable "private_subnet_ids" {}
variable "private_network_cidr" {
  default = "10.0.0.0/8"
}

variable "component" {}
variable "deployment_identifier" {}

variable "service_name" {
  default = ""
}
variable "service_port" {
  default = ""
}
variable "service_certificate_arn" {}

variable "domain_name" {}
variable "public_zone_id" {}
variable "private_zone_id" {}

variable "include_public_dns_record" {
  default = "no"
}
variable "include_private_dns_record" {
  default = "yes"
}

variable "elb_health_check_target" {
  default = "HTTP:80/health"
}
variable "elb_internal" {
  default = true
}
variable "elb_https_allow_cidrs" {
  default = ""
}
