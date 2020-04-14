require 'spec_helper'

describe 'ECS Service ELB' do
  let(:component) { vars.component }
  let(:deployment_identifier) { vars.deployment_identifier }

  let(:access_logs_bucket) { vars.access_logs_bucket }
  let(:access_logs_bucket_prefix) { vars.access_logs_bucket_prefix }
  let(:access_logs_interval) { vars.access_logs_interval.to_i }

  let(:name) { output_for(:harness, 'name') }

  subject {elb(name)}

  it { should exist }
  its(:subnets) {
    should contain_exactly(
        *output_for(:prerequisites, 'subnet_ids', parse: true))
  }
  its(:scheme) { should eq('internal') }

  its(:health_check_target) { should eq(vars.health_check_target) }
  its(:health_check_interval) { should eq(30) }
  its(:health_check_timeout) { should eq(3) }
  its(:health_check_unhealthy_threshold) { should eq(2) }
  its(:health_check_healthy_threshold) { should eq(2) }

  it {should have_listener(
                 protocol: 'HTTPS',
                 port: 443,
                 instance_protocol: 'HTTP',
                 instance_port: vars.service_port.to_i)}

  it 'outputs the zone ID' do
    expect(output_for(:harness, 'zone_id'))
        .to(eq(subject.canonical_hosted_zone_name_id))
  end

  it 'outputs the DNS name' do
    expect(output_for(:harness, 'dns_name'))
        .to(eq(subject.dns_name))
  end

  it 'is associated with the load balancer security group' do
    expect(subject)
        .to(have_security_group(output_for(:harness, 'security_group_id')))
  end

  context 'tags' do
    subject do
      elb_client
          .describe_tags(load_balancer_names: [name])
          .tag_descriptions[0]
          .tags
          .map(&:to_h)
    end

    it {should include({key: 'Name',
                        value: "elb-#{component}-#{deployment_identifier}"})}
    it {should include({key: 'Component', value: component})}
    it {should include({key: 'DeploymentIdentifier',
                        value: deployment_identifier})}
    it {should include({key: 'Service',
                        value: vars.service_name})}
  end

  context 'attributes' do
    subject do
      elb_client
          .describe_load_balancer_attributes(load_balancer_name: name)
          .load_balancer_attributes
    end

    it 'enables cross zone load balancing' do
      cross_zone_attribute = subject.cross_zone_load_balancing.to_h

      expect(cross_zone_attribute).to eq({enabled: true})
    end

    it 'enables connection draining with a timeout of 60 seconds' do
      connection_draining_attribute = subject.connection_draining

      expect(connection_draining_attribute.enabled)
          .to(eq(true))
      expect(connection_draining_attribute.timeout)
          .to(eq(60))
    end

    it 'has an idle timeout of 60 seconds' do
      connection_settings_attribute = subject.connection_settings

      expect(connection_settings_attribute.idle_timeout)
          .to(eq(60))
    end
  end

  context 'access logs' do
    subject do
      elb_client
          .describe_load_balancer_attributes(load_balancer_name: name)
          .load_balancer_attributes
    end

    context 'when disabled' do
      before(:all) do
        reprovision(store_access_logs: 'no')
      end

      it 'has no access log storage' do
        expect(subject.access_log.enabled).to(eq(false))
      end
    end

    context 'when enabled' do
      before(:all) do
        reprovision(store_access_logs: 'yes')
      end

      it 'has access log storage' do
        expect(subject.access_log.enabled).to(eq(true))
      end

      it 'uses the provided bucket name' do
        expect(subject.access_log.s3_bucket_name).to(eq(access_logs_bucket))
      end

      it 'uses the provided bucket prefix' do
        expect(subject.access_log.s3_bucket_prefix)
            .to(eq(access_logs_bucket_prefix))
      end

      it 'uses the provided interval' do
        expect(subject.access_log.emit_interval).to(eq(access_logs_interval))
      end
    end
  end

  context 'when ELB is exposed to the public internet' do
    before(:all) do
      reprovision(expose_to_public_internet: 'yes')
    end

    its(:scheme) {should eq('internet-facing')}
  end

  context 'when ELB is not exposed to the public internet' do
    before(:all) do
      reprovision(expose_to_public_internet: 'no')
    end

    its(:scheme) {should eq('internal')}
  end

  context 'when service protocol is set' do
    before(:all) do
      reprovision(service_protocol: 'https')
    end

    it {should have_listener(
        protocol: 'HTTPS',
        port: 443,
        instance_protocol: 'HTTPS',
        instance_port: vars.service_port.to_i)}
  end
end
