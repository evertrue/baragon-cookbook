#
# Cookbook Name:: baragon
# Recipe:: common
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

node.set['java']['jdk_version'] = 7

include_recipe 'java'

user node['baragon']['user'] do
  supports(manage_home: true)
  home "/home/#{node['baragon']['user']}"
end

%w(/etc/baragon /var/log/baragon).each do |dir|
  directory dir
end

unless node['baragon']['mocking']
  node.set['baragon']['zk_hosts'] =
                    search(:node,
                           "chef_environment:#{node.chef_environment} AND " \
                           'roles:zookeeper').map do |n|
                      "#{n['fqdn']}:#{node['baragon']['zk_port']}"
                    end

  if node['baragon']['zk_hosts'].empty?
    fail 'Search returned no Zookeeper server nodes'
  end
end
