# frozen_string_literal: true

require 'spec_helper'

describe 'full' do
  let(:component) do
    var(role: :full, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :full, name: 'deployment_identifier')
  end
  let(:domain_name) do
    var(role: :full, name: 'domain_name')
  end
  let(:public_zone_id) do
    var(role: :full, name: 'public_zone_id')
  end
  let(:private_zone_id) do
    var(role: :full, name: 'private_zone_id')
  end
  let(:name) do
    output(role: :full, name: 'name')
  end
  let(:subnet_ids) do
    output(role: :full, name: 'subnet_ids')
  end
  let(:vpc_cidr) do
    output(role: :full, name: 'vpc_cidr')
  end
  let(:vpc_id) do
    output(role: :full, name: 'vpc_id')
  end

  before(:context) do
    apply(role: :full)
  end

  after(:context) do
    destroy(
      role: :full,
      only_if: -> { !ENV['FORCE_DESTROY'].nil? || ENV['SEED'].nil? }
    )
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe 'DNS records' do
    let(:load_balancer) do
      elb(name)
    end
    let(:public_hosted_zone) do
      route53_hosted_zone(var(role: :full, name: 'public_zone_id'))
    end
    let(:private_hosted_zone) do
      route53_hosted_zone(var(role: :full, name: 'private_zone_id'))
    end

    it 'outputs the address' do
      expect(output(role: :full, name: 'address'))
        .to(eq("#{component}-#{deployment_identifier}.#{domain_name}"))
    end

    it 'does not create a public DNS entry' do
      expect(public_hosted_zone)
        .not_to(have_record_set(
          "#{component}-#{deployment_identifier}.#{domain_name}."
        )
                  .alias(
                    "#{load_balancer.dns_name}.",
                    load_balancer.canonical_hosted_zone_name_id
                  ))
    end

    it 'creates a private DNS entry' do
      expect(private_hosted_zone)
        .to(have_record_set(
          "#{component}-#{deployment_identifier}.#{domain_name}."
        )
              .alias(
                "#{load_balancer.dns_name}.",
                load_balancer.canonical_hosted_zone_name_id
              ))
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe 'ELB' do
    subject(:load_balancer) { elb(name) }

    let(:access_logs_bucket) do
      var(role: :full, name: 'access_logs_bucket')
    end
    let(:access_logs_bucket_prefix) do
      var(role: :full, name: 'access_logs_bucket_prefix')
    end

    it { is_expected.to(exist) }

    its(:subnets) do
      is_expected.to(match_array(output(role: :full, name: 'subnet_ids')))
    end

    its(:scheme) { is_expected.to(eq('internal')) }

    its(:health_check_target) do
      is_expected.to(eq('HTTP:80/health'))
    end

    its(:health_check_interval) do
      is_expected.to(eq(30))
    end

    its(:health_check_timeout) do
      is_expected.to(eq(3))
    end

    its(:health_check_unhealthy_threshold) do
      is_expected.to(eq(2))
    end

    its(:health_check_healthy_threshold) do
      is_expected.to(eq(2))
    end

    it {
      expect(load_balancer)
        .to(have_listener(
              protocol: 'HTTPS',
              port: 443,
              instance_protocol: 'HTTP',
              instance_port: 8000
            ))
    }

    it 'outputs the zone ID' do
      expect(output(role: :full, name: 'zone_id'))
        .to(eq(load_balancer.canonical_hosted_zone_name_id))
    end

    it 'outputs the DNS name' do
      expect(output(role: :full, name: 'dns_name'))
        .to(eq(load_balancer.dns_name))
    end

    it 'is associated with the load balancer security group' do
      expect(load_balancer)
        .to(have_security_group(output(role: :full, name: 'security_group_id')))
    end

    describe 'tags' do
      subject(:load_balancer_tags) do
        elb_client
          .describe_tags(load_balancer_names: [name])
          .tag_descriptions[0]
          .tags
          .map(&:to_h)
      end

      it {
        expect(load_balancer_tags)
          .to(include(
                key: 'Name',
                value: "elb-#{component}-#{deployment_identifier}"
              ))
      }

      it {
        expect(load_balancer_tags)
          .to(include(
                key: 'Component',
                value: component
              ))
      }

      it {
        expect(load_balancer_tags)
          .to(include(
                key: 'DeploymentIdentifier',
                value: deployment_identifier
              ))
      }

      it {
        expect(load_balancer_tags)
          .to(include(
                key: 'Service',
                value: 'service-1'
              ))
      }
    end

    describe 'attributes' do
      subject(:load_balancer_attributes) do
        elb_client
          .describe_load_balancer_attributes(load_balancer_name: name)
          .load_balancer_attributes
      end

      it 'enables cross zone load balancing' do
        cross_zone_attribute =
          load_balancer_attributes
          .cross_zone_load_balancing
          .to_h

        expect(cross_zone_attribute).to eq({ enabled: true })
      end

      it 'enables connection draining' do
        connection_draining_attribute =
          load_balancer_attributes
          .connection_draining

        expect(connection_draining_attribute.enabled).to(be(true))
      end

      it 'uses a connection draining timeout of 60 seconds' do
        connection_draining_attribute =
          load_balancer_attributes
          .connection_draining

        expect(connection_draining_attribute.timeout).to(eq(60))
      end

      it 'has an idle timeout of 60 seconds' do
        connection_settings_attribute =
          load_balancer_attributes
          .connection_settings

        expect(connection_settings_attribute.idle_timeout).to(eq(60))
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    describe 'access logs' do
      subject(:load_balancer_attributes) do
        elb_client
          .describe_load_balancer_attributes(load_balancer_name: name)
          .load_balancer_attributes
      end

      it 'has access log storage' do
        expect(load_balancer_attributes.access_log.enabled).to(be(true))
      end

      it 'uses the provided bucket name' do
        expect(load_balancer_attributes.access_log.s3_bucket_name)
          .to(eq(access_logs_bucket))
      end

      it 'uses the provided bucket prefix' do
        expect(load_balancer_attributes.access_log.s3_bucket_prefix)
          .to(eq(access_logs_bucket_prefix))
      end

      it 'uses an interval of 60 minutes' do
        expect(load_balancer_attributes.access_log.emit_interval).to(eq(60))
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end

  describe 'security groups' do
    describe 'for load balancer' do
      subject(:load_balancer_security_group) do
        security_group("elb-#{component}-#{deployment_identifier}")
      end

      it { is_expected.to(exist) }

      its(:vpc_id) do
        is_expected.to(eq(output(role: :full, name: 'vpc_id')))
      end

      its(:description) do
        is_expected
          .to(eq("ELB for component: #{component}, " \
                 'service: service-1, ' \
                 "deployment: #{deployment_identifier}"))
      end

      it 'outputs the open to ELB security group ID' do
        expect(output(role: :full, name: 'security_group_id'))
          .to(eq(load_balancer_security_group.id))
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'allows inbound TCP connectivity on all ports from any address ' \
         'within the service' do
        expect(load_balancer_security_group.inbound_rule_count).to(eq(1))

        ingress_rule = load_balancer_security_group.ip_permissions.first

        expect(ingress_rule.from_port).to(eq(443))
        expect(ingress_rule.to_port).to(eq(443))
        expect(ingress_rule.ip_protocol).to(eq('tcp'))
        expect(ingress_rule.ip_ranges.map(&:cidr_ip))
          .to(eq(['10.0.0.0/8']))
      end
      # rubocop:enable RSpec/MultipleExpectations

      # rubocop:disable RSpec/MultipleExpectations
      it 'allows outbound TCP connectivity on all ports and protocols ' \
         'anywhere in the VPC' do
        expect(load_balancer_security_group.outbound_rule_count).to(be(1))

        egress_rule = load_balancer_security_group.ip_permissions_egress.first

        expect(egress_rule.from_port).to(eq(1))
        expect(egress_rule.to_port).to(eq(65_535))
        expect(egress_rule.ip_protocol).to(eq('tcp'))
        expect(egress_rule.ip_ranges.map(&:cidr_ip))
          .to(eq([output(role: :full, name: 'vpc_cidr')]))
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    describe 'for instances' do
      subject(:open_to_load_balancer_security_group) do
        security_group("open-to-elb-#{component}-#{deployment_identifier}")
      end

      let(:load_balancer_security_group) do
        security_group("elb-#{component}-#{deployment_identifier}")
      end

      it { is_expected.to(exist) }

      its(:vpc_id) do
        is_expected.to(eq(output(role: :full, name: 'vpc_id')))
      end

      its(:description) do
        is_expected
          .to(eq("Open to ELB for component: #{component}, " \
                 'service: service-1, ' \
                 "deployment: #{deployment_identifier}"))
      end

      it 'outputs the open to load balancer security group ID' do
        security_group_id =
          output(role: :full, name: 'open_to_load_balancer_security_group_id')
        expect(security_group_id)
          .to(eq(open_to_load_balancer_security_group.id))
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'allows inbound TCP connectivity on the service port from the ' \
         'ELB security group' do
        elb_security_group =
          security_group("elb-#{component}-#{deployment_identifier}")

        expect(open_to_load_balancer_security_group.inbound_rule_count)
          .to(eq(1))

        matching_permission = open_to_load_balancer_security_group
                              .ip_permissions
                              .find do |permission|
          permission.user_id_group_pairs.find do |pair|
            pair.group_id == elb_security_group.id
          end
        end

        expect(matching_permission).not_to(be_nil)
        expect(matching_permission.from_port).to(eq(8000))
        expect(matching_permission.to_port).to(eq(8000))
        expect(matching_permission.ip_protocol).to(eq('tcp'))
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
