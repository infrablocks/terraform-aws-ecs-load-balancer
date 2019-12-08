output "name" {
  value = module.ecs_load_balancer.name
}

output "zone_id" {
  value = module.ecs_load_balancer.zone_id
}

output "dns_name" {
  value = module.ecs_load_balancer.dns_name
}

output "address" {
  value = module.ecs_load_balancer.address
}

output "security_group_id" {
  value = module.ecs_load_balancer.security_group_id
}

output "open_to_load_balancer_security_group_id" {
  value = module.ecs_load_balancer.open_to_load_balancer_security_group_id
}
