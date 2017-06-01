#
# Cookbook Name:: baragon
# Resource:: agent
#
# Copyright 2014, EverTrue, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default_action :create

property :group, String, name_attribute: true
property :port, Integer, required: true
property :config, Hash
property :templates, Array

action :create do
  run_context.include_recipe 'baragon::common'

  # Take the agent_yaml attribute as a template and customize it
  agent_yaml = node['baragon']['agent_yaml'].to_hash
  agent_yaml.deep_merge! config.to_hash if config
  agent_root_path = "#{agent_yaml['loadBalancerConfig']['rootPath']}/#{group}"

  agent_yaml['loadBalancerConfig']['name'] = group
  agent_yaml['server']['connector']['port'] = port
  agent_yaml['loadBalancerConfig']['rootPath'] = agent_root_path
  agent_yaml['templates'] = templates || node['baragon']['templates'].to_hash.values

  # Process the templates as ERB
  agent_yaml['templates'].each { |item| item['template'] = ERB.new(item['template']).result(binding) }

  # Set the zk hosts and namespace.  These get set in baragon::common
  agent_yaml['zookeeper']['quorum'] = node['baragon']['zk_hosts'].join(',')
  agent_yaml['zookeeper']['zkNamespace'] = node['baragon']['zk_namespace']

  # Set the config check command for baragon to check nginx configs
  if node['nginx']
    unless node['nginx']['binary']
      fail "attribute :binary not found in node['nginx']: #{node['nginx'].inspect}"
    end
    agent_yaml['loadBalancerConfig']['checkConfigCommand'] = "#{node['nginx']['binary']} -t"
    agent_yaml['loadBalancerConfig']['reloadConfigCommand'] = "#{node['nginx']['binary']} -s reload"
  else
    agent_yaml['loadBalancerConfig']['checkConfigCommand'] = '/bin/true'
    agent_yaml['loadBalancerConfig']['reloadConfigCommand'] = '/bin/true'
  end

  ["#{agent_root_path}/proxy",
   "#{agent_root_path}/upstreams"].each do |dir|
    directory dir do
      recursive true
    end
  end

  # Install Baragon Agent
  case node['baragon']['install_type']
  when 'source'
    run_context.include_recipe 'baragon::build'

    remote_file "/usr/share/java/BaragonAgentService-#{node['baragon']['version']}-shaded.jar" do
      mode 0644
      source "file://#{file_cache_path('Baragon', 'BaragonAgentService', 'target')}" \
             "BaragonAgentService-#{node['baragon']['version']}-SNAPSHOT-shaded.jar"
    end
  when 'package'
    run_context.include_recipe 'maven'

    execute 'update-ca-certificates' do
      command 'update-ca-certificates -f'
      only_if { node['platform_version'].to_i < 16 }
    end

    maven 'BaragonAgentService' do
      group_id 'com.hubspot'
      classifier 'shaded'
      version node['baragon']['version']
      dest '/usr/share/java'
    end
  else
    fail "Unsupported install type: #{node['baragon']['install_type']}"
  end

  file "/etc/baragon/agent-#{group}.yml" do
    mode 0644
    content yaml_config(agent_yaml.to_hash)
    notifies :restart, "service[baragon-agent-#{new_resource.group}]"
  end

  # Configure the log file location and rotation
  agent_log = "#{node['baragon']['agent_log_base']}/baragon_agent_#{group}.log"

  logrotate_app "baragon_agent_#{group}" do
    path agent_log
    size '100M'
    rotate 3
    create '644 root root'
    options %w(missingok copytruncate)
  end

  # Install upstart service template and start the service
  if node['platform_version'].to_i < 16
    template "/etc/init/baragon-agent-#{group}.conf" do
      source 'upstart/baragon-agent.init.erb'
      cookbook 'baragon'
      notifies :restart, "service[baragon-agent-#{new_resource.group}]"
      variables config_yaml: "/etc/baragon/agent-#{new_resource.group}.yml",
                agent_log: agent_log
    end
  else
    template "/etc/systemd/system/baragon-agent-#{group}.service" do
      source 'systemd/baragon-agent.service.erb'
      cookbook 'baragon'
      notifies :restart, "service[baragon-agent-#{new_resource.group}]"
      variables config_yaml: "/etc/baragon/agent-#{new_resource.group}.yml",
                agent_log: agent_log,
                group: group
    end
  end

  service "baragon-agent-#{group}" do
    if node['platform_version'].to_i < 16
      provider Chef::Provider::Service::Upstart
    else
      provider Chef::Provider::Service::Systemd
    end
    supports status: true,
             restart: true
    action [:enable, :start]
  end
end

action :delete do
  agent_root_path = "#{config['loadBalancerConfig']['rootPath']}/#{group}"

  service "baragon-agent-#{group}" do
    if node['platform_version'].to_i < 16
      provider Chef::Provider::Service::Upstart
    else
      provider Chef::Provider::Service::Systemd
    end
    supports status: true,
             restart: true
    action [:disable, :stop]
  end

  ["/etc/baragon/agent-#{group}.yml",
   "/etc/init/baragon-agent-#{group}.conf",
   "/usr/share/java/BaragonAgentService-#{node['baragon']['version']}-shaded.jar"].each do |f|
    file f do
      action :delete
    end
  end

  ["#{agent_root_path}/proxy",
   "#{agent_root_path}/upstreams"].each do |dir|
    directory dir do
      recursive true
      action :delete
      notifies :reload, 'service[nginx]' if node['nginx']
    end
  end

  logrotate_app "baragon_agent_#{group}" do
    enable false
  end
end
