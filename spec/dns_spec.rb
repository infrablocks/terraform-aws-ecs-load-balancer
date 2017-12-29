require 'spec_helper'
require 'awspec/type/route53_hosted_zone'

describe 'DNS Records' do
  include_context :terraform

  let(:component) {vars.component}
  let(:deployment_identifier) {vars.deployment_identifier}

  let(:name) {output_for(:harness, 'name')}

  let(:domain_name) {vars.domain_name}

  let(:load_balancer) {elb(name)}

  let(:public_hosted_zone) {
    route53_hosted_zone(vars.public_zone_id)
  }

  let(:private_hosted_zone) {
    route53_hosted_zone(vars.private_zone_id)
  }

  it 'outputs the address' do
    expect(output_for(:harness, 'address'))
        .to(eq("#{component}-#{deployment_identifier}.#{domain_name}"))
  end

  context 'public' do
    context 'when included' do
      before(:all) do
        reprovision(include_public_dns_record: 'yes')
      end

      it 'creates a public DNS entry' do
        expect(public_hosted_zone)
            .to(have_record_set(
                    "#{component}-#{deployment_identifier}.#{domain_name}.")
                    .alias(
                        "#{load_balancer.dns_name}.",
                        load_balancer.canonical_hosted_zone_name_id))
      end
    end

    context 'when not included' do
      before(:all) do
        reprovision(include_public_dns_record: 'no')
      end

      it 'does not create a public DNS entry' do
        expect(public_hosted_zone)
            .not_to(have_record_set(
                        "#{component}-#{deployment_identifier}.#{domain_name}.")
                        .alias(
                            "#{load_balancer.dns_name}.",
                            load_balancer.canonical_hosted_zone_name_id))
      end
    end
  end

  context 'private' do
    context 'when included' do
      before(:all) do
        reprovision(include_private_dns_record: 'yes')
      end

      it 'creates a private DNS entry' do
        expect(private_hosted_zone)
            .to(have_record_set(
                    "#{component}-#{deployment_identifier}.#{domain_name}.")
                    .alias(
                        "#{load_balancer.dns_name}.",
                        load_balancer.canonical_hosted_zone_name_id))
      end
    end

    context 'when not included' do
      before(:all) do
        reprovision(include_private_dns_record: 'no')
      end

      it 'does not create a private DNS entry' do
        expect(private_hosted_zone)
            .not_to(have_record_set(
                        "#{component}-#{deployment_identifier}.#{domain_name}.")
                        .alias(
                            "#{load_balancer.dns_name}.",
                            load_balancer.canonical_hosted_zone_name_id))
      end
    end
  end
end