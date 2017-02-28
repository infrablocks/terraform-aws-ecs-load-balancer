output "vpc_id" {
  value = "${module.base_network.vpc_id}"
}

output "public_subnet_ids" {
  value = "${module.base_network.public_subnet_ids}"
}

output "private_subnet_ids" {
  value = "${module.base_network.private_subnet_ids}"
}
