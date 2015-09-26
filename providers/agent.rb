#
# Cookbook Name:: baragon
# Provider:: agent
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

use_inline_resources

action :create do
  run_context.include_recipe 'baragon::common'

  # Take the agent_yaml as a template and customize it
  agent_yaml = new_resource.config
  agent_root_path = "#{agent_yaml['loadBalancerConfig']['rootPath']}/#{new_resource.group}"

  agent_yaml['loadBalancerConfig']['name'] = new_resource.group
  agent_yaml['server']['connector']['port'] = new_resource.port
  agent_yaml['loadBalancerConfig']['rootPath'] = agent_root_path
  agent_yaml['templates'] = [node['baragon']['proxy_template'],
                             node['baragon']['upstream_template']]

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
      source "file://#{Chef::Config[:file_cache_path]}/Baragon/" \
             'BaragonAgentService/target/' \
             "BaragonAgentService-#{node['baragon']['version']}-SNAPSHOT-shaded.jar"
    end
  when 'package'
    run_context.include_recipe 'maven'

    maven 'BaragonAgentService' do
      group_id 'com.hubspot'
      classifier 'shaded'
      version node['baragon']['version']
      dest '/usr/share/java'
    end
  else
    fail "Unsupported install type: #{node['baragon']['install_type']}"
  end

  file "/etc/baragon/agent-#{new_resource.group}.yml" do
    mode 0644
    content yaml_config(agent_yaml)
    notifies :restart, "service[baragon-agent-#{new_resource.group}]"
  end

  # Configure the log file location and rotation
  agent_log = "#{node['baragon']['agent_log_base']}/baragon_agent_#{new_resource.group}.log"

  logrotate_app "baragon_agent_#{new_resource.group}" do
    path agent_log
    size '100M'
    rotate 3
    create '644 root root'
    options %w(missingok copytruncate)
  end

  # Install upstart service template and start the service
  template "/etc/init/baragon-agent-#{new_resource.group}.conf" do
    source 'baragon-agent.init.erb'
    cookbook 'baragon'
    mode 0644
    notifies :restart, "service[baragon-agent-#{new_resource.group}]"
    variables config_yaml: "/etc/baragon/agent-#{new_resource.group}.yml",
              agent_log: agent_log
  end

  service "baragon-agent-#{new_resource.group}" do
    provider Chef::Provider::Service::Upstart
    supports status: true,
             restart: true
    action [:enable, :start]
  end
end

action :delete do
  agent_root_path = "#{new_resource.config['loadBalancerConfig']['rootPath']}/#{new_resource.group}"

  service "baragon-agent-#{new_resource.group}" do
    provider Chef::Provider::Service::Upstart
    supports status: true,
             restart: true
    action [:disable, :stop]
  end

  ["/etc/baragon/agent-#{new_resource.group}.yml",
   "/etc/init/baragon-agent-#{new_resource.group}.conf",
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

  logrotate_app "baragon_agent_#{new_resource.group}" do
    enable false
  end
end
