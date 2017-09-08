require 'spec_helper'
require 'awspec/type/route53_hosted_zone'

describe 'DNS Records' do
  include_context :terraform

  let(:component) { vars.component }
  let(:deployment_identifier) { vars.deployment_identifier }
  let(:domain_name) { vars.domain_name }

  let(:service_name) { vars.service_name }

  let(:public_zone_id) { vars.public_zone_id }
  let(:private_zone_id) { vars.private_zone_id }

  let(:load_balancer) {
    elb(output_with_name('service_elb_name'))
  }

  let(:public_hosted_zone) {
    route53_hosted_zone(public_zone_id)
  }

  let(:private_hosted_zone) {
    route53_hosted_zone(private_zone_id)
  }

  context 'public' do
    it 'creates a public dns entry when requested' do
      expect(public_hosted_zone)
          .to(have_record_set("#{component}-#{deployment_identifier}.#{domain_name}.")
                  .alias(
                      "#{load_balancer.dns_name}.",
                      load_balancer.canonical_hosted_zone_name_id))
    end
  end

  context 'private' do
    it 'creates a private dns entry when requested' do
      expect(private_hosted_zone)
          .not_to(have_record_set("#{component}-#{deployment_identifier}.#{domain_name}.")
                  .alias(
                      "#{load_balancer.dns_name}.",
                      load_balancer.canonical_hosted_zone_name_id))
    end
  end
end