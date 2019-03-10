data "terraform_remote_state" "prerequisites" {
  backend = "local"

  config {
    path = "${path.module}/../../../../state/prerequisites.tfstate"
  }
}

module "ecs_load_balancer" {
  source = "../../../../"

  component = "${var.component}"
  deployment_identifier = "${var.deployment_identifier}"

  region = "${var.region}"
  vpc_id = "${data.terraform_remote_state.prerequisites.vpc_id}"
  subnet_ids = "${split(",", data.terraform_remote_state.prerequisites.subnet_ids)}"

  service_name = "${var.service_name}"
  service_port = "${var.service_port}"

  service_certificate_arn = "${data.terraform_remote_state.prerequisites.certificate_arn}"

  domain_name = "${var.domain_name}"
  public_zone_id = "${var.public_zone_id}"
  private_zone_id = "${var.private_zone_id}"

  health_check_target = "${var.health_check_target}"

  allow_cidrs = "${var.allow_cidrs}"
  egress_cidrs = "${var.egress_cidrs}"

  include_public_dns_record = "${var.include_public_dns_record}"
  include_private_dns_record = "${var.include_private_dns_record}"

  expose_to_public_internet = "${var.expose_to_public_internet}"

  access_logs_bucket = "${var.access_logs_bucket}"
  access_logs_bucket_prefix = "${var.access_logs_bucket_prefix}"
  access_logs_interval = "${var.access_logs_interval}"

  store_access_logs = "${var.store_access_logs}"
}
