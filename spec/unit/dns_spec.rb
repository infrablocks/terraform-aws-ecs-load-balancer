# frozen_string_literal: true

require 'spec_helper'

describe 'DNS records' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:public_zone_id) do
    var(role: :root, name: 'public_zone_id')
  end
  let(:private_zone_id) do
    var(role: :root, name: 'private_zone_id')
  end
  let(:domain_name) do
    var(role: :root, name: 'domain_name')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'does not create a public DNS entry' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_route53_record')
                  .with_attribute_value(:zone_id, public_zone_id))
    end

    it 'creates a private DNS entry' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, private_zone_id))
    end

    it 'derives the name of the private DNS entry from the component, ' \
       'deployment identifier and domain name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, private_zone_id)
              .with_attribute_value(
                :name, "#{component}-#{deployment_identifier}.#{domain_name}"
              ))
    end

    it 'uses a type of "A" for the private DNS entry' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, private_zone_id)
              .with_attribute_value(
                :name, "#{component}-#{deployment_identifier}.#{domain_name}"
              ))
    end

    it 'does not evaluate target health for the private DNS entry' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, private_zone_id)
              .with_attribute_value(
                [:alias, 0, :evaluate_target_health], false
              ))
    end

    it 'outputs the address' do
      expect(@plan)
        .to(include_output_creation(name: 'address')
              .with_value(
                "#{component}-#{deployment_identifier}.#{domain_name}"
              ))
    end
  end

  describe 'when include_public_dns_record is "no"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_public_dns_record = 'no'
      end
    end

    it 'does not create a public DNS entry' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_route53_record')
                  .with_attribute_value(:zone_id, public_zone_id))
    end
  end

  describe 'when include_public_dns_record is "yes"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_public_dns_record = 'yes'
      end
    end

    it 'creates a public DNS entry' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, public_zone_id))
    end

    it 'derives the name of the public DNS entry from the component, ' \
       'deployment identifier and domain name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, public_zone_id)
              .with_attribute_value(
                :name, "#{component}-#{deployment_identifier}.#{domain_name}"
              ))
    end

    it 'uses a type of "A" for the public DNS entry' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, public_zone_id)
              .with_attribute_value(
                :name, "#{component}-#{deployment_identifier}.#{domain_name}"
              ))
    end

    it 'does not evaluate target health for the public DNS entry' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, public_zone_id)
              .with_attribute_value(
                [:alias, 0, :evaluate_target_health], false
              ))
    end
  end

  describe 'when include_private_dns_record is "no"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_private_dns_record = 'no'
      end
    end

    it 'does not create a private DNS entry' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_route53_record')
                  .with_attribute_value(:zone_id, private_zone_id))
    end
  end

  describe 'when include_private_dns_record is "yes"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_private_dns_record = 'yes'
      end
    end

    it 'creates a private DNS entry' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, private_zone_id))
    end

    it 'derives the name of the private DNS entry from the component, ' \
       'deployment identifier and domain name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, private_zone_id)
              .with_attribute_value(
                :name, "#{component}-#{deployment_identifier}.#{domain_name}"
              ))
    end

    it 'uses a type of "A" for the private DNS entry' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, private_zone_id)
              .with_attribute_value(
                :name, "#{component}-#{deployment_identifier}.#{domain_name}"
              ))
    end

    it 'does not evaluate target health for the private DNS entry' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_record')
              .with_attribute_value(:zone_id, private_zone_id)
              .with_attribute_value(
                [:alias, 0, :evaluate_target_health], false
              ))
    end
  end
end
