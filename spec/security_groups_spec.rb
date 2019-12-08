require 'spec_helper'

describe 'Security Groups' do
  let(:component) {vars.component}
  let(:deployment_identifier) {vars.deployment_identifier}

  context 'for load balancer' do
    subject {security_group("elb-#{component}-#{deployment_identifier}")}

    it {should exist}
    its(:vpc_id) {should eq(output_for(:prerequisites, 'vpc_id'))}
    its(:description) {should eq("ELB for component: #{component}, service: #{vars.service_name}, deployment: #{deployment_identifier}")}

    it 'outputs the open to ELB security group ID' do
      expect(output_for(:harness, 'security_group_id'))
          .to(eq(subject.id))
    end

    it 'allows inbound TCP connectivity on all ports from any address within the Service' do
      expect(subject.inbound_rule_count).to(eq(1))

      ingress_rule = subject.ip_permissions.first

      expect(ingress_rule.from_port).to(eq(443))
      expect(ingress_rule.to_port).to(eq(443))
      expect(ingress_rule.ip_protocol).to(eq('tcp'))
      expect(ingress_rule.ip_ranges.map(&:cidr_ip)).to(eq(vars.allow_cidrs))
    end

    context 'when no egress CIDRs are supplied' do
      before(:all) do
        reprovision(egress_cidrs: [])
      end

      it 'allows outbound TCP connectivity on all ports and protocols anywhere in the VPC' do
        expect(subject.outbound_rule_count).to(be(1))

        egress_rule = subject.ip_permissions_egress.first

        expect(egress_rule.from_port).to(eq(1))
        expect(egress_rule.to_port).to(eq(65535))
        expect(egress_rule.ip_protocol).to(eq('tcp'))
        expect(egress_rule.ip_ranges.map(&:cidr_ip))
            .to(eq([output_for(:prerequisites, 'vpc_cidr')]))
      end
    end

    context 'when egress CIDRs are supplied' do
      before(:all) do
        reprovision(
            egress_cidrs: ['10.0.0.0/8', '192.168.0.0/16'])
      end

      it 'allows outbound TCP connectivity on all ports and protocols anywhere in the VPC' do
        expect(subject.outbound_rule_count).to(be(2))

        egress_rule = subject.ip_permissions_egress.first

        expect(egress_rule.from_port).to(eq(1))
        expect(egress_rule.to_port).to(eq(65535))
        expect(egress_rule.ip_protocol).to(eq('tcp'))
        expect(egress_rule.ip_ranges.map(&:cidr_ip))
            .to(eq(['192.168.0.0/16', '10.0.0.0/8']))
      end
    end
  end

  context "for instances" do
    subject {security_group("open-to-elb-#{component}-#{deployment_identifier}")}

    let(:load_balancer_security_group) do
      security_group("elb-#{component}-#{deployment_identifier}")
    end

    it { should exist }
    its(:vpc_id) {should eq(output_for(:prerequisites, 'vpc_id'))}
    its(:description) {should eq("Open to ELB for component: #{component}, service: #{vars.service_name}, deployment: #{deployment_identifier}")}

    it 'outputs the open to load balancer security group ID' do
      expect(output_for(:harness, 'open_to_load_balancer_security_group_id'))
          .to(eq(subject.id))
    end

    it 'allows inbound TCP connectivity on the service port from the ELB security group' do
      elb_security_group = security_group("elb-#{component}-#{deployment_identifier}")

      expect(subject.inbound_rule_count).to(eq(1))

      permission = subject.ip_permissions.find do |permission|
        permission.user_id_group_pairs.find do |pair|
          pair.group_id == elb_security_group.id
        end
      end

      expect(permission).not_to(be(nil))
      expect(permission.from_port).to(eq(vars.service_port))
      expect(permission.to_port).to(eq(vars.service_port))
      expect(permission.ip_protocol).to(eq('tcp'))
    end
  end
end
