locals {
  address = "${var.component}-${var.deployment_identifier}.${var.domain_name}"
}

data "aws_caller_identity" "current" {}

module "base_network" {
  source  = "infrablocks/base-networking/aws"
  version = "4.0.0"

  vpc_cidr = var.vpc_cidr
  region = var.region
  availability_zones = var.availability_zones

  component = var.component
  deployment_identifier = var.deployment_identifier

  private_zone_id = var.private_zone_id
}

module "acm_certificate" {
  source = "infrablocks/acm-certificate/aws"
  version = "1.1.0"

  domain_name = local.address
  domain_zone_id = var.public_zone_id
  subject_alternative_name_zone_id = var.public_zone_id

  providers = {
    aws.certificate = aws
    aws.domain_validation = aws
    aws.san_validation = aws
  }
}

resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = var.access_logs_bucket
  force_destroy = true
}

data "aws_iam_policy_document" "access_logs_bucket_policy" {
  statement {
    actions = ["s3:PutObject"]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.access_logs_bucket}/${var.access_logs_bucket_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    principals {
      identifiers = [lookup(var.load_balancer_account_ids, var.region)]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs_bucket" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  policy = data.aws_iam_policy_document.access_logs_bucket_policy.json
}
