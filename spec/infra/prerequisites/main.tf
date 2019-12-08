data "aws_caller_identity" "current" {}

module "base_network" {
  source  = "infrablocks/base-networking/aws"
  version = "2.0.0"

  vpc_cidr = var.vpc_cidr
  region = var.region
  availability_zones = var.availability_zones

  component = var.component
  deployment_identifier = var.deployment_identifier

  private_zone_id = var.private_zone_id
}

resource "aws_iam_server_certificate" "service" {
  name = "wildcard-certificate-${var.component}-${var.deployment_identifier}"
  private_key = file(var.service_certificate_private_key)
  certificate_body = file(var.service_certificate_body)
}

resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = var.access_logs_bucket
  force_destroy = true
}

data "template_file" "access_logs_bucket_policy" {
  template = file("${path.root}/policies/bucket-policy.json.tpl")

  vars = {
    bucket_name = var.access_logs_bucket
    bucket_prefix = var.access_logs_bucket_prefix
    account_id = data.aws_caller_identity.current.account_id
    load_balancer_account_id = lookup(var.load_balancer_account_ids, var.region)
  }
}

resource "aws_s3_bucket_policy" "access_logs_bucket" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  policy = data.template_file.access_logs_bucket_policy.rendered
}
