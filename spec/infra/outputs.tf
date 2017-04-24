output "vpc_id" {
  value = "${module.base_network.vpc_id}"
}

output "public_subnet_ids" {
  value = "${module.base_network.public_subnet_ids}"
}

output "private_subnet_ids" {
  value = "${module.base_network.private_subnet_ids}"
}

output "service_elb_name" {
  value = "${module.ecs_load_balancer.service_elb_name}"
}

output "service_dns_name" {
  value = "${module.ecs_load_balancer.service_dns_name}"
}


