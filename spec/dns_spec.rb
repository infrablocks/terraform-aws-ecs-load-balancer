require 'spec_helper'
require 'awspec/type/route53_hosted_zone'

describe 'DNS Records' do
  include_context :terraform

  let(:component) {RSpec.configuration.component}
  let(:deployment_identifier) {RSpec.configuration.deployment_identifier}
  let(:domain_name) {RSpec.configuration.domain_name}

  let(:service_name) {RSpec.configuration.service_name}

  let(:public_zone_id) {RSpec.configuration.public_zone_id}
  let(:private_zone_id) {RSpec.configuration.private_zone_id}

  let(:load_balancer) {
    elb("elb-#{service_name}-#{component}-#{deployment_identifier}")
  }

  let(:public_hosted_zone) {
    route53_hosted_zone(public_zone_id)
  }

  let(:private_hosted_zone) {
    route53_hosted_zone(private_zone_id)
  }

  context "public" do
    it 'creates a public dns entry when requested' do
      expect(public_hosted_zone)
          .to(have_record_set("#{component}-#{deployment_identifier}.#{domain_name}.")
                  .alias(
                      "#{load_balancer.dns_name}.",
                      load_balancer.canonical_hosted_zone_name_id))
    end
  end

  context "private" do
    it 'creates a private dns entry when requested' do
      expect(private_hosted_zone)
          .not_to(have_record_set("#{component}-#{deployment_identifier}.#{domain_name}.")
                  .alias(
                      "#{load_balancer.dns_name}.",
                      load_balancer.canonical_hosted_zone_name_id))
    end
  end
end