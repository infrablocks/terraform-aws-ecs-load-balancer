require 'spec_helper'

describe 'ECS Service ELB' do
  include_context :terraform

  let(:component) { vars.component }
  let(:deployment_identifier) { vars.deployment_identifier }
  let(:domain_name) { vars.domain_name }

  let(:service_name) { vars.service_name }

  let(:elb_internal) { vars.elb_internal }
  let(:elb_health_check_target) { vars.elb_health_check_target }
  let(:elb_https_allow_cidrs) { vars.elb_https_allow_cidrs }

  let(:vpc_id) { output_with_name('vpc_id') }

  let(:public_subnet_ids) { output_with_name('public_subnet_ids') }
  let(:private_subnet_ids) { output_with_name('private_subnet_ids') }

  let(:private_network_cidr) { vars.private_network_cidr }

  context 'elb' do
    subject {
      elb("elb-#{service_name}-#{component}-#{deployment_identifier}")
    }

    let(:expected_subnets) do
      elb_internal ?
          private_subnet_ids.split(',') :
          public_subnet_ids.split(',')
    end

    let(:expected_scheme) do
      elb_internal ?
          'internal' :
          'internet-facing'
    end

    it { should exist }

    its(:scheme) { should eq(expected_scheme) }
    its(:subnets) { should contain_exactly(*expected_subnets) }
    its(:health_check_target) { should eq(elb_health_check_target) }
    its(:health_check_interval) { should eq(30) }
    its(:health_check_timeout) { should eq(3) }
    its(:health_check_unhealthy_threshold) { should eq(2) }
    its(:health_check_healthy_threshold) { should eq(2) }

    it 'outputs the ELB name' do
      expect(output_with_name('service_elb_name'))
          .to(eq(subject.load_balancer_name))
    end
  end

  context 'service record' do
    it 'outputs the service record name' do
      expect(output_with_name('service_dns_name'))
          .to(eq("#{component}-#{deployment_identifier}.#{domain_name}"))
    end
  end

  context 'elb security group' do
    subject { security_group("elb-#{component}-#{deployment_identifier}") }

    let(:elb_allowed_cidrs) do
      elb_internal ?
          [private_network_cidr] :
          [elb_https_allow_cidrs]
    end

    it { should exist }
    its(:vpc_id) { should eq(vpc_id) }
    its(:description) { should eq("#{component}-elb") }

    it 'allows inbound TCP connectivity on all ports from any address within the Service' do
      expect(subject.inbound_rule_count).to(eq(1))

      ingress_rule = subject.ip_permissions.first

      expect(ingress_rule.from_port).to(eq(443))
      expect(ingress_rule.to_port).to(eq(443))
      expect(ingress_rule.ip_protocol).to(eq('tcp'))
      expect(ingress_rule.ip_ranges.map(&:cidr_ip)).to(eq([elb_https_allow_cidrs]))
    end

    it 'allows outbound TCP connectivity on all ports and protocols anywhere' do
      expect(subject.outbound_rule_count).to(be(1))

      egress_rule = subject.ip_permissions_egress.first

      expect(egress_rule.from_port).to(eq(1))
      expect(egress_rule.to_port).to(eq(65535))
      expect(egress_rule.ip_protocol).to(eq('tcp'))
      expect(egress_rule.ip_ranges.map(&:cidr_ip)).to(eq([private_network_cidr]))
    end
  end

  context 'open-to-elb security group' do
    subject { security_group("open-to-elb-#{component}-#{deployment_identifier}") }

    it { should exist }
    its(:vpc_id) { should eq(vpc_id) }
    its(:description) { should eq("#{component}-open-to-elb") }

    it 'allows inbound TCP connectivity on port 443 from the ELB security group' do
      elb_security_group = security_group("elb-#{component}-#{deployment_identifier}")

      expect(subject.inbound_rule_count).to(eq(1))

      permission = subject.ip_permissions.find do |permission|
        permission.user_id_group_pairs.find do |pair|
          pair.group_id == elb_security_group.id
        end
      end

      expect(permission).not_to(be(nil))
      expect(permission.from_port).to(eq(443))
      expect(permission.to_port).to(eq(443))
      expect(permission.ip_protocol).to(eq('tcp'))
    end
  end
end