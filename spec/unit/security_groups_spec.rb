# frozen_string_literal: true

require 'spec_helper'

describe 'security groups' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:service_name) do
    var(role: :root, name: 'service_name')
  end
  let(:service_port) do
    var(role: :root, name: 'service_port')
  end
  let(:allow_cidrs) do
    var(role: :root, name: 'allow_cidrs')
  end
  let(:vpc_id) do
    output(role: :prerequisites, name: 'vpc_id')
  end
  let(:vpc_cidr) do
    output(role: :prerequisites, name: 'vpc_cidr')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'creates a load balancer security group' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'load_balancer'
        )
              .once)
    end

    it 'uses the provided VPC ID on the load balancer security group' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'load_balancer'
        )
              .with_attribute_value(:vpc_id, vpc_id))
    end

    it 'derives the load balancer security group name from the component ' \
       'and deployment identifier' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'load_balancer'
        )
              .with_attribute_value(
                :name, "elb-#{component}-#{deployment_identifier}"
              ))
    end

    it 'includes the component, deployment identifier and service name ' \
       'in the load balancer security group description' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'load_balancer'
        )
              .with_attribute_value(
                :description,
                including(component)
                  .and(including(deployment_identifier))
                  .and(including(service_name))
              ))
    end

    it 'allows TCP ingress on port 443 for the provided allowed CIDRs ' \
       'in the load balancer security group' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'load_balancer'
        )
              .with_attribute_value(
                [:ingress, 0],
                a_hash_including(
                  from_port: 443,
                  to_port: 443,
                  protocol: 'tcp',
                  cidr_blocks: allow_cidrs
                )
              ))
    end

    it 'allows TCP egress on all ports for the VPC CIDR ' \
       'in the load balancer security group' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'load_balancer'
        )
              .with_attribute_value(
                [:egress, 0],
                a_hash_including(
                  from_port: 1,
                  to_port: 65_535,
                  protocol: 'tcp',
                  cidr_blocks: [vpc_cidr]
                )
              ))
    end

    it 'creates an open to load balancer security group' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'open_to_load_balancer'
        )
              .once)
    end

    it 'uses the provided VPC ID on the open to load balancer security group' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'open_to_load_balancer'
        )
              .with_attribute_value(:vpc_id, vpc_id))
    end

    it 'derives the open to load balancer security group name from ' \
       'the component and deployment identifier' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'open_to_load_balancer'
        )
              .with_attribute_value(
                :name, "open-to-elb-#{component}-#{deployment_identifier}"
              ))
    end

    it 'includes the component, deployment identifier and service name ' \
       'in the open to load balancer security group description' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'open_to_load_balancer'
        )
              .with_attribute_value(
                :description,
                including(component)
                  .and(including(deployment_identifier))
                  .and(including(service_name))
              ))
    end

    it 'allows TCP ingress on the service port in the open to ' \
       'load balancer security group' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'open_to_load_balancer'
        )
              .with_attribute_value(
                [:ingress, 0],
                a_hash_including(
                  from_port: service_port.to_i,
                  to_port: service_port.to_i,
                  protocol: 'tcp'
                )
              ))
    end

    it 'outputs the load balancer security group ID' do
      expect(@plan)
        .to(include_output_creation(name: 'security_group_id'))
    end

    it 'outputs the open to load balancer security group ID' do
      expect(@plan)
        .to(include_output_creation(
              name: 'open_to_load_balancer_security_group_id'
            ))
    end
  end

  describe 'when egress_cidrs provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.egress_cidrs = %w[
          10.1.0.0/16
          10.2.0.0/16
        ]
      end
    end

    it 'allows TCP egress on all ports for the provided CIDRs ' \
       'in the load balancer security group' do
      expect(@plan)
        .to(include_resource_creation(
          type: 'aws_security_group',
          name: 'load_balancer'
        )
              .with_attribute_value(
                [:egress, 0],
                a_hash_including(
                  from_port: 1,
                  to_port: 65_535,
                  protocol: 'tcp',
                  cidr_blocks: containing_exactly(
                    '10.1.0.0/16',
                    '10.2.0.0/16'
                  )
                )
              ))
    end
  end
end
