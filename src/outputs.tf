output "service_elb_name" {
  value = "${aws_elb.service.name}"
}

output "service_dns_name" {
  value = "${aws_route53_record.service_public.name}"
}