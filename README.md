Terraform AWS ECS Load Balancer
===============================

A Terraform module for building an elastic load balancer for an ECS service in 
AWS.

The ECS load balancer requires:
* An existing VPC
* Some existing public and private subnets
* A domain name and public and private hosted zones
 
The ECS load balancer consists of:
* An ELB
  * Listening as HTTPS on port 443 using the provided certificate
  * Forwarding as HTTP on the provided service port to any registered instances
  * Using cross zone load balancing across the provided subnet IDs
  * Either internal or external depending on the provided parameter
  * With a health check using the specified target
* A security group allowing access to the load balancer on port 443
  * From the private network CIDR
  * From the specified CIDRs
* A DNS entry for the service
  * In the public hosted zone
  * In the private hosted zone

![Diagram of infrastructure managed by this module](/docs/architecture.png?raw=true)

Usage
-----

To use the module, include something like the following in your terraform 
configuration:

```hcl-terraform
module "ecs_cluster" {
  source = "git@github.com:tobyclemson/terraform-aws-load-balancer.git//src"

  region = "eu-west-2"
  vpc_id = "vpc-fb7dc365"
  public_subnet_ids = "subnet-ae4533c4,subnet-443e6b12"
  private_subnet_ids = "subnet-eb32c271,subnet-64872d1f"
  private_network_cidr = "192.168.0.0/16"
  
  component = "important-component"
  deployment_identifier = "production"
  
  service_name = "memcache"
  service_port = "11211"
  service_certificate_arn = "arn:aws:acm:eu-west-2:121408295202:certificate/4e0452c7-d32d-4abd-b5f2-69490e83c936"
  
  domain_name = "example.com"
  public_zone_id = "Z1WA3EVJBXSQ2V"
  private_zone_id = "Z3CVA9QD5NHSW3"
  
  elb_health_check_target = "TCP:11211"
  elb_internal = false
  elb_https_allow_cidrs = "100.10.10.0/24,200.20.0.0/16"
}
```

Executing `terraform get` will fetch the module.

As mentioned above, the elastic load balancer deploys into an existing base 
network. Whilst the base network can be created using any mechanism you like, 
the 
[AWS Base Networking](https://github.com/tobyclemson/terraform-aws-base-networking)
module will create everything you need. See the 
[docs](https://github.com/tobyclemson/terraform-aws-base-networking/blob/master/README.md)
for usage instructions.


### Inputs

| Name                                 | Description                                                    | Default            | Required |
|--------------------------------------|----------------------------------------------------------------|:------------------:|:--------:|
| region                               | The region into which to deploy the load balancer              | -                  | yes      |
| vpc_id                               | The ID of the VPC into which to deploy the load balancer       | -                  | yes      |
| public_subnet_ids                    | The IDs of the public subnets for the ELB if it is public      | -                  | yes      |
| private_subnet_ids                   | The IDs of the private subnets for the ELB if it is internal   | -                  | yes      |
| private_network_cidr                 | The CIDR of the private network allowed access to the ELB      | 10.0.0.0/8         | yes      |
| component                            | The component for which the load balancer is being created     | -                  | yes      |
| deployment_identifier                | An identifier for this instantiation                           | -                  | yes      |
| service_name                         | The name of the service for which the ELB is being created     | default            | yes      |
| service_port                         | The port on which the service containers are listening         | -                  | yes      |
| service_certificate_arn              | The ARN of a certificate to use for TLS terminating at the ELB | t2.medium          | yes      |
| domain_name                          | The domain name of the supplied Route 53 zones                 | -                  | yes      |
| public_zone_id                       | The ID of the public Route 53 zone                             | -                  | yes      |
| private_zone_id                      | The ID of the private Route 53 zone                            | -                  | yes      |
| elb_health_check_target              | The target to use for health checks                            | HTTP:80/ping       | yes      |
| elb_internal                         | Whether or not the ELB is internal only                        | true               | yes      |
| elb_https_allow_cidrs                | The CIDRs from which the ELB is reachable                      | -                  | yes      |

### Outputs

| Name                      | Description                                                          |
|---------------------------|----------------------------------------------------------------------|
| service_elb_name          | The name of the created ELB                                          |
| service_dns_name          | The name of the service DNS record                                   |


Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed 
on your development machine:

* Ruby (2.3.1)
* Bundler
* git
* git-crypt
* gnupg
* direnv

#### Mac OS X Setup

Installing the required tools is best managed by [homebrew](http://brew.sh).

To install homebrew:

```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, to install the required tools:

```
# ruby
brew install rbenv
brew install ruby-build
echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
eval "$(rbenv init -)"
rbenv install 2.3.1
rbenv rehash
rbenv local 2.3.1
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

To provision module infrastructure, run tests and then destroy that 
infrastructure, execute:

```bash
./go
```

To provision the module test contents:

```bash
./go provision:aws[<deployment_identifier>]
```

To destroy the module test contents:

```bash
./go destroy:aws[<deployment_identifier>]
```

### Common Tasks

To generate an SSH key pair:

```
ssh-keygen -t rsa -b 4096 -C integration-test@example.com -N '' -f config/secrets/keys/bastion/ssh
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at 
https://github.com/tobyclemson/terraform-aws-ecs-load-balancer. 
This project is intended to be a safe, welcoming space for collaboration, and 
contributors are expected to adhere to the 
[Contributor Covenant](http://contributor-covenant.org) code of conduct.


License
-------

The library is available as open source under the terms of the 
[MIT License](http://opensource.org/licenses/MIT).
