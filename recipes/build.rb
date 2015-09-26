#
# Cookbook Name:: baragon
# Recipe:: build
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

directory file_cache_path('Baragon') do
  owner node['baragon']['user']
end

execute 'build_baragon' do
  # Maven (or rather npm) has issues with
  # being run as root.
  user        node['baragon']['user']
  environment HOME: '/home/baragon'
  command     '/usr/bin/mvn clean package -DskipTests'
  cwd         file_cache_path('Baragon')
  action      :nothing
end

package 'maven'

include_recipe 'git'

git file_cache_path('Baragon') do
  repository 'https://github.com/HubSpot/Baragon.git'
  reference  node['baragon']['git_ref']
  user       node['baragon']['user']
  notifies   :run, 'execute[build_baragon]', :immediately
end
