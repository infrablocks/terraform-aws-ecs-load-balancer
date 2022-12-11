# frozen_string_literal: true

require 'spec_helper'

describe 'ELB' do
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
  let(:subnet_ids) do
    output(role: :prerequisites, name: 'subnet_ids')
  end
  let(:certificate_arn) do
    output(role: :prerequisites, name: 'certificate_arn')
  end
  let(:access_logs_bucket) do
    output(role: :prerequisites, name: 'access_logs_bucket')
  end
  let(:access_logs_bucket_prefix) do
    output(role: :prerequisites, name: 'access_logs_bucket_prefix')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'creates a load balancer' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .once)
    end

    it 'uses the provided subnets' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(:subnets, contain_exactly(*subnet_ids)))
    end

    it 'marks the load balancer as internal' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(:internal, true))
    end

    it 'enables cross zone load balancing' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(:cross_zone_load_balancing, true))
    end

    it 'uses an idle timeout of 60 seconds' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(:idle_timeout, 60))
    end

    it 'uses connection draining' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(:connection_draining, true))
    end

    it 'uses a connection draining timeout of 60 seconds' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(:connection_draining_timeout, 60))
    end

    it 'uses the provided service port for the listener instance port' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:listener, 0, :instance_port], service_port.to_i
              ))
    end

    it 'uses "http" for the listener instance protocol' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:listener, 0, :instance_protocol], 'http'
              ))
    end

    it 'uses 443 for the listener load balancer port' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:listener, 0, :lb_port], 443
              ))
    end

    it 'uses "https" for the listener load balancer protocol' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:listener, 0, :lb_protocol], 'https'
              ))
    end

    it 'uses the provided certificate ARN' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:listener, 0, :ssl_certificate_id], certificate_arn
              ))
    end

    it 'uses a health check healthy threshold of 2' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:health_check, 0, :healthy_threshold], 2
              ))
    end

    it 'uses a health check unhealthy threshold of 2' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:health_check, 0, :unhealthy_threshold], 2
              ))
    end

    it 'uses a health check timeout of 3 seconds' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:health_check, 0, :timeout], 3
              ))
    end

    it 'uses a health check interval of 30 seconds' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:health_check, 0, :interval], 30
              ))
    end

    it 'uses a health check target of "HTTP:80/health"' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:health_check, 0, :target], 'HTTP:80/health'
              ))
    end

    it 'adds tags to the load balancer' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Name: "elb-#{component}-#{deployment_identifier}",
                  Component: component,
                  DeploymentIdentifier: deployment_identifier,
                  Service: service_name
                )
              ))
    end

    it 'does not enable access logs' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(:access_logs, a_nil_value))
    end

    it 'outputs the load balancer name' do
      expect(@plan)
        .to(include_output_creation(name: 'name'))
    end

    it 'outputs the load balancer zone ID' do
      expect(@plan)
        .to(include_output_creation(name: 'zone_id'))
    end

    it 'outputs the load balancer DNS name' do
      expect(@plan)
        .to(include_output_creation(name: 'dns_name'))
    end
  end

  describe 'when expose_to_public_internet is "yes"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.expose_to_public_internet = 'yes'
      end
    end

    it 'marks the load balancer as internet-facing' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(:internal, false))
    end
  end

  describe 'when expose_to_public_internet is "no"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.expose_to_public_internet = 'no'
      end
    end

    it 'marks the load balancer as internal' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(:internal, true))
    end
  end

  describe 'when health_check_target is provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.health_check_target = 'HTTP:80/'
      end
    end

    it 'uses the provided health check target' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:health_check, 0, :target], 'HTTP:80/'
              ))
    end
  end

  describe 'when access_logs_bucket is an empty string' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.access_logs_bucket = ''
      end
    end

    it 'does not configure access logging' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(:access_logs, a_nil_value))
    end
  end

  describe 'when access_logs_bucket is provided and store_access_logs ' \
           'is not provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.access_logs_bucket =
          output(role: :prerequisites, name: 'access_logs_bucket')
      end
    end

    it 'sets the access logs bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :bucket], access_logs_bucket
              ))
    end

    it 'does not enable access logging' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :enabled], false
              ))
    end
  end

  describe 'when access_logs_bucket is provided and store_access_logs ' \
           'is "no"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.access_logs_bucket =
          output(role: :prerequisites, name: 'access_logs_bucket')
        vars.store_access_logs = 'no'
      end
    end

    it 'sets the access logs bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :bucket], access_logs_bucket
              ))
    end

    it 'uses an empty string for the bucket prefix' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :bucket_prefix], ''
              ))
    end

    it 'uses an interval of 60 minutes' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :interval], 60
              ))
    end

    it 'does not enable access logging' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :enabled], false
              ))
    end
  end

  describe 'when access_logs_bucket is provided and store_access_logs ' \
           'is "yes"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.access_logs_bucket =
          output(role: :prerequisites, name: 'access_logs_bucket')
        vars.store_access_logs = 'yes'
      end
    end

    it 'sets the access logs bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :bucket], access_logs_bucket
              ))
    end

    it 'uses an empty string for the bucket prefix' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :bucket_prefix], ''
              ))
    end

    it 'uses an interval of 60' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :interval], 60
              ))
    end

    it 'enables access logging' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :enabled], true
              ))
    end
  end

  describe 'when access_logs_bucket_prefix is provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.access_logs_bucket =
          output(role: :prerequisites, name: 'access_logs_bucket')
        vars.access_logs_bucket_prefix =
          output(role: :prerequisites, name: 'access_logs_bucket_prefix')
      end
    end

    it 'uses the provided bucket prefix' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :bucket_prefix], access_logs_bucket_prefix
              ))
    end
  end

  describe 'when access_logs_interval is provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.access_logs_bucket =
          output(role: :prerequisites, name: 'access_logs_bucket')
        vars.access_logs_interval = 5
      end
    end

    it 'uses the provided bucket prefix' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_elb')
              .with_attribute_value(
                [:access_logs, 0, :interval], 5
              ))
    end
  end
end
