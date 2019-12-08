output "name" {
  description = "The name of the created ELB."
  value = aws_elb.service.name
}

output "zone_id" {
  description = "The zone ID of the created ELB."
  value = aws_elb.service.zone_id
}

output "dns_name" {
  description = "The DNS name of the created ELB."
  value = aws_elb.service.dns_name
}

output "address" {
  description = "The name of the service DNS record."
  value = "${var.component}-${var.deployment_identifier}.${var.domain_name}"
}

output "security_group_id" {
  description = "The ID of the security group associated with the ELB."
  value = aws_security_group.load_balancer.id
}

output "open_to_load_balancer_security_group_id" {
  description = "The ID of the security group allowing access from the ELB."
  value = aws_security_group.open_to_load_balancer.id
}
