## 0.1.9 (September 9th, 2017) 

IMPROVEMENTS:

* The zone ID and the DNS name of the ELB are now output from the module.

## 0.1.8 (September 8th, 2017)

BACKWARDS INCOMPATIBILITIES / NOTES:

* A load balancer name is no longer provided and instead terraform chooses a
  unique name. This is to work around the 32 character issue in ELB names.
  This will force a redeploy of the load balancer.
* The `elb_internal` variable is now called `expose_to_public_internet`
* The module no longer takes both `public_subnet_ids` and `private_subnet_ids`
  and instead takes only `subnet_ids`. The `subnet_ids` variable is now a list.
* The module no longer takes `private_network_cidr` or `elb_https_allow_cidrs` 
  variables. Instead, there are `allow_cidrs` and `egress_cidrs` list variables. 
  `allow_cidrs` specifies the CIDRs that can access the load balancer and 
  `egress_cidrs` specifies the CIDRs that are accessible by the load balancer. 
  If no `egress_cidrs` are specified, the CIDR of the VPC is used instead.
* The `elb_health_check_target` variable is now called `health_check_target`. 

IMPROVEMENTS:

* The IDs of the security group for the load balancer and the security group 
  open to the load balancer are now exposed as outputs, `security_group_id` and
  `open_to_load_balancer_security_group_id` respectively.
