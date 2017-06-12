require 'bundler/setup'

require 'awspec'
require 'securerandom'

require 'support/shared_contexts/terraform'

require_relative '../lib/terraform'
require_relative '../lib/public_ip'

RSpec.configure do |config|
  deployment_identifier = ENV['DEPLOYMENT_IDENTIFIER']

  config.example_status_persistence_file_path = '.rspec_status'
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.add_setting :vpc_cidr, default: "10.1.0.0/16"
  config.add_setting :region, default: 'eu-west-2'
  config.add_setting :availability_zones, default: 'eu-west-2a,eu-west-2b'
  config.add_setting :private_network_cidr, default: '10.0.0.0/8'

  config.add_setting :component, default: 'test'
  config.add_setting :deployment_identifier,
                     default: deployment_identifier || SecureRandom.hex[0, 8]

  config.add_setting :bastion_ami, default: 'ami-bb373ddf'
  config.add_setting :bastion_ssh_public_key_path, default: 'config/secrets/keys/bastion/ssh.public'
  config.add_setting :bastion_ssh_allow_cidrs, default: PublicIP.as_cidr

  config.add_setting :domain_name, default: 'greasedscone.uk'
  config.add_setting :public_zone_id, default: 'Z4Q2X3ESOZT4N'
  config.add_setting :private_zone_id, default: 'Z2CDAFD23Q10HO'

  config.add_setting :include_public_dns_record, default: 'yes'
  config.add_setting :include_private_dns_record, default: 'no'

  config.add_setting :service_name, default: "service-1"
  config.add_setting :service_port, default: 80

  config.add_setting :service_certificate_body, default: 'config/secrets/certificates/cert.pem'
  config.add_setting :service_certificate_private_key, default: 'config/secrets/certificates/ssl.key'

  config.add_setting :elb_internal, default: false
  config.add_setting :elb_health_check_target, default: "HTTP:#{RSpec.configuration.service_port}/"
  config.add_setting :elb_https_allow_cidrs, default: PublicIP.as_cidr

  config.add_setting :infrastructure_events_bucket, default: 'tobyclemson-open-source'

  config.before(:suite) do
    variables = RSpec.configuration
    configuration_directory = Paths.from_project_root_directory('spec/infra')

    puts
    puts "Provisioning with deployment identifier: #{variables.deployment_identifier}"
    puts

    Terraform.clean
    Terraform.get(directory: configuration_directory)
    Terraform.apply(directory: configuration_directory, vars: {
        vpc_cidr: variables.vpc_cidr,
        region: variables.region,
        availability_zones: variables.availability_zones,
        private_network_cidr: variables.private_network_cidr,

        component: variables.component,
        deployment_identifier: variables.deployment_identifier,

        bastion_ami: variables.bastion_ami,
        bastion_ssh_public_key_path: variables.bastion_ssh_public_key_path,
        bastion_ssh_allow_cidrs: variables.bastion_ssh_allow_cidrs,

        domain_name: variables.domain_name,
        public_zone_id: variables.public_zone_id,
        private_zone_id: variables.private_zone_id,

        include_public_dns_record: variables.include_public_dns_record,
        include_private_dns_record: variables.include_private_dns_record,

        service_name: variables.service_name,
        service_port: variables.service_port,

        service_certificate_body: variables.service_certificate_body,
        service_certificate_private_key: variables.service_certificate_private_key,

        elb_internal: variables.elb_internal,
        elb_health_check_target: variables.elb_health_check_target,
        elb_https_allow_cidrs: variables.elb_https_allow_cidrs,

        infrastructure_events_bucket: variables.infrastructure_events_bucket
    })
  end

  config.after(:suite) do
    unless deployment_identifier
      variables = RSpec.configuration
      configuration_directory = Paths.from_project_root_directory('spec/infra')

      puts
      puts "Destroying with deployment identifier: #{variables.deployment_identifier}"
      puts

      Terraform.clean
      Terraform.get(directory: configuration_directory)
      Terraform.destroy(
          directory: configuration_directory,
          force: true,
          vars: {
              vpc_cidr: variables.vpc_cidr,
              region: variables.region,
              availability_zones: variables.availability_zones,
              private_network_cidr: variables.private_network_cidr,

              component: variables.component,
              deployment_identifier: variables.deployment_identifier,

              bastion_ami: variables.bastion_ami,
              bastion_ssh_public_key_path: variables.bastion_ssh_public_key_path,
              bastion_ssh_allow_cidrs: variables.bastion_ssh_allow_cidrs,

              domain_name: variables.domain_name,
              public_zone_id: variables.public_zone_id,
              private_zone_id: variables.private_zone_id,

              include_public_dns_record: variables.include_public_dns_record,
              include_private_dns_record: variables.include_private_dns_record,

              service_name: variables.service_name,
              service_port: variables.service_port,

              service_certificate_body: variables.service_certificate_body,
              service_certificate_private_key: variables.service_certificate_private_key,

              elb_internal: variables.elb_internal,
              elb_health_check_target: variables.elb_health_check_target,
              elb_https_allow_cidrs: variables.elb_https_allow_cidrs,

              infrastructure_events_bucket: variables.infrastructure_events_bucket
          })

      puts
    end
  end
end
