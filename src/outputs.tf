output "service_elb_name" {
  value = "${aws_elb.service.name}"
}

output "service_dns_name" {
  value = "${var.component}-${var.deployment_identifier}.${var.domain_name}"
}