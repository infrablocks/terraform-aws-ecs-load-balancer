module "ecs_load_balancer" {
  source = "./../../"

  component = var.component
  deployment_identifier = var.deployment_identifier

  region = var.region
  vpc_id = module.base_network.vpc_id
  subnet_ids = module.base_network.private_subnet_ids

  service_name = "service-1"
  service_port = "8000"

  service_certificate_arn = module.acm_certificate.certificate_arn

  domain_name = var.domain_name
  public_zone_id = var.public_zone_id
  private_zone_id = var.private_zone_id

  allow_cidrs = ["10.0.0.0/8"]

  store_access_logs = "yes"
  access_logs_bucket = var.access_logs_bucket
  access_logs_bucket_prefix = var.access_logs_bucket_prefix
}
