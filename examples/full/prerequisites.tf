locals {
  address                   = "${var.component}-${var.deployment_identifier}.${var.domain_name}"
  load_balancer_account_ids = {
    us-east-1      = "127311923021"
    us-east-2      = "033677994240"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
    ca-central-1   = "985666609251"
    eu-central-1   = "054676820928"
    eu-west-1      = "156460612806"
    eu-west-2      = "652711504416"
    eu-west-3      = "009996457667"
    eu-north-1     = "897822967062"
    ap-northeast-1 = "582318560864"
    ap-northeast-2 = "600734575887"
    ap-northeast-3 = "383597477331"
    ap-southeast-1 = "114774131450"
    ap-southeast-2 = "783225319266"
    ap-south-1     = "718504428378"
    sa-east-1      = "507241528517"
  }
}

data "aws_caller_identity" "current" {}

module "base_network" {
  source  = "infrablocks/base-networking/aws"
  version = "4.0.0"

  vpc_cidr           = var.vpc_cidr
  region             = var.region
  availability_zones = var.availability_zones

  component             = var.component
  deployment_identifier = var.deployment_identifier

  private_zone_id = var.private_zone_id

  include_nat_gateways = "no"
}

module "acm_certificate" {
  source  = "infrablocks/acm-certificate/aws"
  version = "1.1.0"

  domain_name                      = local.address
  domain_zone_id                   = var.public_zone_id
  subject_alternative_name_zone_id = var.public_zone_id

  providers = {
    aws.certificate       = aws
    aws.domain_validation = aws
    aws.san_validation    = aws
  }
}

resource "aws_s3_bucket" "access_logs_bucket" {
  bucket        = var.access_logs_bucket
  force_destroy = true
}

data "aws_iam_policy_document" "access_logs_bucket_policy" {
  statement {
    actions   = ["s3:PutObject"]
    effect    = "Allow"
    resources = [
      "arn:aws:s3:::${var.access_logs_bucket}/${var.access_logs_bucket_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    principals {
      identifiers = [lookup(local.load_balancer_account_ids, var.region)]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs_bucket" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  policy = data.aws_iam_policy_document.access_logs_bucket_policy.json
}
