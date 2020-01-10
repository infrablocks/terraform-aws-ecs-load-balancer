resource "aws_elb" "service" {
  subnets = var.subnet_ids
  security_groups = [
    aws_security_group.load_balancer.id
  ]

  internal = var.expose_to_public_internet == "yes" ? false : true

  cross_zone_load_balancing = true
  idle_timeout = 60
  connection_draining = true
  connection_draining_timeout = 60

  listener {
    instance_port = var.service_port
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = var.service_certificate_arn
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = var.health_check_target
    interval = 30
  }

  tags = {
    Name = "elb-${var.component}-${var.deployment_identifier}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Service = var.service_name
  }

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != "" ? [1] : []
    content {
      bucket = var.access_logs_bucket
      bucket_prefix = var.access_logs_bucket_prefix
      interval = var.access_logs_interval
      enabled = var.store_access_logs == "yes" ? true : false
    }
  }
}
