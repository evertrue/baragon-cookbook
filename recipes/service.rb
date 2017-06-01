#
# Cookbook Name:: baragon
# Recipe:: service
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

include_recipe 'baragon::common'

case node['baragon']['install_type']
when 'source'
  include_recipe 'baragon::build'

  remote_file "/usr/share/java/BaragonService-#{node['baragon']['version']}-shaded.jar" do
    mode     0644
    source   "file://#{file_cache_path('Baragon', 'BaragonService', 'target')}" \
             "BaragonService-#{node['baragon']['version']}-SNAPSHOT-shaded.jar"
  end
when 'package'
  include_recipe 'maven'

  maven 'BaragonService' do
    group_id 'com.hubspot'
    classifier 'shaded'
    version node['baragon']['version']
    dest '/usr/share/java'
  end
else
  fail "Unsupported install type: #{node['baragon']['install_type']}"
end

node.set['baragon']['service_yaml']['zookeeper']['quorum'] =
  node['baragon']['zk_hosts'].join(',')
node.set['baragon']['service_yaml']['zookeeper']['zkNamespace'] =
  node['baragon']['zk_namespace']

file '/etc/baragon/service.yml' do
  mode     0644
  content  yaml_config(node['baragon']['service_yaml'].to_hash)
  notifies :restart, 'service[baragon-server]'
end

if node['platform_version'].to_i < 16
  template '/etc/init/baragon-server.conf' do
    source    'upstart/baragon-server.init.erb'
    notifies  :restart, 'service[baragon-server]'
    variables config_yaml: '/etc/baragon/service.yml'
  end
else
  template '/etc/systemd/system/baragon-server.service' do
    source    'systemd/baragon-server.service.erb'
    notifies  :restart, 'service[baragon-server]'
    variables config_yaml: '/etc/baragon/service.yml'
  end
end

logrotate_app 'baragon_server' do
  path node['baragon']['service_log']
  size '100M'
  rotate 3
  create '644 root root'
  options %w(missingok copytruncate compress)
end

service 'baragon-server' do
  if node['platform_version'].to_i < 16
    provider Chef::Provider::Service::Upstart
  else
    provider Chef::Provider::Service::Systemd
  end
  supports status: true,
           restart: true
  action   [:enable, :start]
end
