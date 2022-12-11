Terraform AWS ECS Load Balancer
===============================

[![CircleCI](https://circleci.com/gh/infrablocks/terraform-aws-ecs-load-balancer.svg?style=svg)](https://circleci.com/gh/infrablocks/terraform-aws-ecs-load-balancer)

A Terraform module for building an elastic load balancer for an ECS service in 
AWS.

The ECS load balancer requires:
* An existing VPC
* Some existing subnets
* A domain name and public and private hosted zones
 
The ECS load balancer consists of:
* An ELB
  * Listening as HTTPS on port 443 using the provided certificate
  * Forwarding as HTTP on the provided service port to any registered instances
  * Using cross zone load balancing across the provided subnet IDs
  * Either internal or internet-facing depending on the provided parameter
  * With a health check using the specified target
* A security group allowing access to the load balancer on port 443 from the 
  specified CIDRs
* A security group for use by targets allowing access from the load balancer 
  on the service port.
* A DNS entry for the service
  * In the public hosted zone if requested
  * In the private hosted zone if requested

![Diagram of infrastructure managed by this module](https://raw.githubusercontent.com/infrablocks/terraform-aws-ecs-load-balancer/main/docs/architecture.png)

Usage
-----

To use the module, include something like the following in your Terraform
configuration:

```hcl-terraform
module "ecs_load_balancer" {
  source = "infrablocks/ecs-load-balancer/aws"
  version = "0.1.10"

  region = "eu-west-2"
  vpc_id = "vpc-fb7dc365"
  subnet_ids = "subnet-ae4533c4,subnet-443e6b12"
  
  component = "important-component"
  deployment_identifier = "production"
  
  service_name = "memcache"
  service_port = "11211"
  service_certificate_arn = "arn:aws:acm:eu-west-2:121408295202:certificate/4e0452c7-d32d-4abd-b5f2-69490e83c936"
  
  domain_name = "example.com"
  public_zone_id = "Z1WA3EVJBXSQ2V"
  private_zone_id = "Z3CVA9QD5NHSW3"
  
  health_check_target = "TCP:11211"
  
  allow_cidrs = [
    "100.10.10.0/24",
    "200.20.0.0/16"
  ]
  
  include_public_dns_record = "yes"
  include_private_dns_record = "yes"
  
  expose_to_public_internet = "yes"
}
```

As mentioned above, the elastic load balancer deploys into an existing base 
network. Whilst the base network can be created using any mechanism you like, 
the 
[AWS Base Networking](https://github.com/infrablocks/terraform-aws-base-networking)
module will create everything you need. See the 
[docs](https://github.com/infrablocks/terraform-aws-base-networking/blob/main/README.md)
for usage instructions.

See the 
[Terraform registry entry](https://registry.terraform.io/modules/infrablocks/ecs-load-balancer/aws/latest) 
for more details.

### Inputs

| Name                                 | Description                                                    | Default             | Required |
|--------------------------------------|----------------------------------------------------------------|:-------------------:|:--------:|
| region                               | The region into which to deploy the load balancer              | -                   | yes      |
| vpc_id                               | The ID of the VPC into which to deploy the load balancer       | -                   | yes      |
| subnet_ids                           | The IDs of the subnets for the ELB to deploy into              | -                   | yes      |
| component                            | The component for which the load balancer is being created     | -                   | yes      |
| deployment_identifier                | An identifier for this instantiation                           | -                   | yes      |
| service_name                         | The name of the service for which the ELB is being created     | default             | yes      |
| service_port                         | The port on which the service containers are listening         | -                   | yes      |
| service_certificate_arn              | The ARN of a certificate to use for TLS terminating at the ELB | -                   | yes      |
| domain_name                          | The domain name of the supplied Route 53 zones                 | -                   | yes      |
| public_zone_id                       | The ID of the public Route 53 zone                             | -                   | yes      |
| private_zone_id                      | The ID of the private Route 53 zone                            | -                   | yes      |
| health_check_target                  | The target to use for health checks                            | HTTP:80/ping        | yes      |
| allow_cidrs                          | A list of CIDRs from which the ELB is reachable                | -                   | yes      |
| egress_cidrs                         | A list of CIDRs which the ELB can reach                        | the CIDR of the VPC | no       |
| include_public_dns_record            | Whether or not to create a public DNS record ("yes" or "no")   | "no"                | yes      |
| include_private_dns_record           | Whether or not to create a private DNS record ("yes" or "no")  | "yes"               | yes      |
| expose_to_public_internet            | Whether or not the ELB is publicly accessible ("yes" or "no")  | "no"                | yes      |


### Outputs

| Name                                    | Description                                                          |
|-----------------------------------------|----------------------------------------------------------------------|
| name                                    | The name of the created ELB                                          |
| zone_id                                 | The zone ID of the created ELB                                       |
| dns_name                                | The DNS name of the created ELB                                      |
| address                                 | The name of the service DNS record                                   |
| security_group_id                       | The ID of the security group associated with the ELB                 |
| open_to_load_balancer_security_group_id | The ID of the security group allowing access from the ELB            |

### Compatibility

This module is compatible with Terraform versions greater than or equal to 
Terraform 1.0.

Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed 
on your development machine:

* Ruby (3.1.1)
* Bundler
* git
* git-crypt
* gnupg
* direnv
* aws-vault

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
rbenv install 3.1.1
rbenv rehash
rbenv local 3.1.1
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# aws-vault
brew cask install

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

Running the build requires an AWS account and AWS credentials. You are free to 
configure credentials however you like as long as an access key ID and secret
access key are available. These instructions utilise 
[aws-vault](https://github.com/99designs/aws-vault) which makes credential
management easy and secure.

To provision module infrastructure, run tests and then destroy that 
infrastructure, execute:

```bash
aws-vault exec <profile> -- ./go
```

To provision the module prerequisites:

```bash
aws-vault exec <profile> -- ./go deployment:prerequisites:provision[<deployment_identifier>]
```

To provision the module contents:

```bash
aws-vault exec <profile> -- ./go deployment:root:provision[<deployment_identifier>]
```

To destroy the module contents:

```bash
aws-vault exec <profile> -- ./go deployment:root:destroy[<deployment_identifier>]
```

To destroy the module prerequisites:

```bash
aws-vault exec <profile> -- ./go deployment:prerequisites:destroy[<deployment_identifier>]
```

Configuration parameters can be overridden via environment variables:

```bash
DEPLOYMENT_IDENTIFIER=testing aws-vault exec <profile> -- ./go
```

When a deployment identifier is provided via an environment variable, 
infrastructure will not be destroyed at the end of test execution. This can
be useful during development to avoid lengthy provision and destroy cycles.

By default, providers will be downloaded for each terraform execution. To
cache providers between calls:

```bash
TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache" aws-vault exec <profile> -- ./go
```

### Common Tasks

#### Generating an SSH key pair

To generate an SSH key pair:

```
ssh-keygen -m PEM -t rsa -b 4096 -C integration-test@example.com -N '' -f config/secrets/keys/bastion/ssh
```

#### Generating a self-signed certificate

To generate a self signed certificate:

```
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout config/secrets/certificates/ssl.key \
  -out config/secrets/certificates/cert.pem \
  -subj /CN=example.com \
  -reqexts SAN \
  -config <(cat /etc/ssl/openssl.cnf \
    <(printf "\n[SAN]\nsubjectAltName=DNS:example.com,DNS:www.example.com,IP:10.0.0.1"))
```

To decrypt the resulting key:

```
openssl rsa -in key.pem -out ssl.key
```

#### Managing CircleCI keys

To encrypt a GPG key for use by CircleCI:

```bash
openssl aes-256-cbc \
  -e \
  -md sha1 \
  -in ./config/secrets/ci/gpg.private \
  -out ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

To check decryption is working correctly:

```bash
openssl aes-256-cbc \
  -d \
  -md sha1 \
  -in ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at 
https://github.com/infrablocks/terraform-aws-ecs-load-balancer. This project is
intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the 
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

License
-------

The library is available as open source under the terms of the 
[MIT License](http://opensource.org/licenses/MIT).
