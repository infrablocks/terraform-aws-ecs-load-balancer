locals {
  # default for cases when `null` value provided, meaning "use default"
  health_check_target        = var.health_check_target == null ? "HTTP:80/health" : var.health_check_target
  egress_cidrs               = var.egress_cidrs == null ? [] : var.egress_cidrs
  include_public_dns_record  = var.include_public_dns_record == null ? "no" : var.include_public_dns_record
  include_private_dns_record = var.include_private_dns_record == null ? "yes" : var.include_private_dns_record
  expose_to_public_internet  = var.expose_to_public_internet == null ? "no" : var.expose_to_public_internet
  access_logs_bucket         = var.access_logs_bucket == null ? "" : var.access_logs_bucket
  access_logs_bucket_prefix  = var.access_logs_bucket_prefix == null ? "" : var.access_logs_bucket_prefix
  access_logs_interval       = var.access_logs_interval == null ? 60 : var.access_logs_interval
  store_access_logs          = var.store_access_logs == null ? "no" : var.store_access_logs
}
