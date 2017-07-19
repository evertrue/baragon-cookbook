#
# Cookbook Name:: baragon
# Recipe:: agent
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

# The way that we use add_header below necessitates this requirement. In Ubuntu < 16 nginx still
# tries to add the header even if the set value is an empty string (which breaks the `map` logic
# we use here).
#
# This weird trick is described here: https://serverfault.com/a/598106
fail 'This cookbook no longer supports Ubuntu < 16' unless node['platform_version'].to_i >= 16

# Installs a default baragon agent via the baragon_agent LWRP

baragon_agent 'default' do
  port 8882
  config 'zookeeper' => { 'sessionTimeoutMillis' => 50_000 }
end
