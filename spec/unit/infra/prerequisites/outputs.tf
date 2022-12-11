output "vpc_id" {
  value = module.base_network.vpc_id
}

output "vpc_cidr" {
  value = module.base_network.vpc_cidr
}

output "subnet_ids" {
  value = module.base_network.public_subnet_ids
}

output "certificate_arn" {
  value = module.acm_certificate.certificate_arn
}

output "domain_name" {
  value = var.domain_name
}

output "public_zone_id" {
  value = var.public_zone_id
}

output "private_zone_id" {
  value = var.private_zone_id
}

output "access_logs_bucket" {
  value = var.access_logs_bucket
}
output "access_logs_bucket_prefix" {
  value = var.access_logs_bucket_prefix
}
