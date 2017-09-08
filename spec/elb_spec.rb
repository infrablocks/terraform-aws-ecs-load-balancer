require 'spec_helper'

describe 'ECS Service ELB' do
  let(:component) { vars.component }
  let(:deployment_identifier) { vars.deployment_identifier }

  let(:name) { output_with_name('name') }

  subject {elb(name)}

  it { should exist }
  its(:subnets) { should contain_exactly(*output_with_name('subnet_ids').split(',')) }
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
                 instance_port: vars.service_port)}

  it 'is associated with the load balancer security group' do
    expect(subject)
        .to(have_security_group(output_with_name('security_group_id')))
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
end