variable "region" {}
variable "vpc_cidr" {}
variable "availability_zones" {}
variable "private_network_cidr" {}

variable "component" {}
variable "deployment_identifier" {}

variable "bastion_ami" {}
variable "bastion_ssh_public_key_path" {}
variable "bastion_ssh_allow_cidrs" {}

variable "domain_name" {}
variable "public_zone_id" {}
variable "private_zone_id" {}

variable "infrastructure_events_bucket" {}

variable "service_name" {}
variable "service_port" {}

variable "service_certificate_body" {}
variable "service_certificate_private_key" {}

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
