variable "region" {
  description = "The region into which to deploy the load balancer."
  type = string
}
variable "vpc_id" {
  description = "The ID of the VPC into which to deploy the load balancer."
  type = string
}
variable "subnet_ids" {
  description = "The IDs of the subnets for the ELB to deploy into."
  type = list(string)
}

variable "component" {
  description = "The component for which the load balancer is being created."
  type = string
}
variable "deployment_identifier" {
  description = "An identifier for this instantiation."
  type = string
}

variable "service_name" {
  description = "The name of the service for which the ELB is being created."
  type = string
}
variable "service_port" {
  description = "The port on which the service containers are listening."
  type = string
}
variable "service_certificate_arn" {
  description = "The ARN of a certificate to use for TLS terminating at the ELB."
  type = string
}

variable "domain_name" {
  description = "The domain name of the supplied Route 53 zones."
  type = string
}
variable "public_zone_id" {
  description = "The ID of the public Route 53 zone."
  type = string
}
variable "private_zone_id" {
  description = "The ID of the private Route 53 zone."
  type = string
}

variable "health_check_target" {
  description = "The target to use for health checks."
  type = string
  default = "HTTP:80/health"
}
variable "allow_cidrs" {
  description = "A list of CIDRs from which the ELB is reachable."
  type = list(string)
}

variable "egress_cidrs" {
  description = "A list of CIDRs which the ELB can reach."
  type = list(string)
  default = []
}

variable "include_public_dns_record" {
  description = "Whether or not to create a public DNS record (\"yes\" or \"no\")."
  type = string
  default = "no"
}
variable "include_private_dns_record" {
  description = "Whether or not to create a private DNS record (\"yes\" or \"no\")."
  type = string
  default = "yes"
}

variable "expose_to_public_internet" {
  description = "Whether or not the ELB is publicly accessible (\"yes\" or \"no\")."
  type = string
  default = "no"
}

variable "access_logs_bucket" {
  description = ""
  type = string
  default = ""
}
variable "access_logs_bucket_prefix" {
  description = ""
  type = string
  default = ""
}
variable "access_logs_interval" {
  description = ""
  type = number
  default = 60
}

variable "store_access_logs" {
  description = "Whether or not access logs of the ELB should be stored."
  type = string
  default = "no"
}
