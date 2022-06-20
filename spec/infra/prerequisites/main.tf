data "aws_caller_identity" "current" {}

data "terraform_remote_state" "permanent" {
  backend = "local"

  config = {
    path = "${path.module}/../../../../state/permanent.tfstate"
  }
}

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
