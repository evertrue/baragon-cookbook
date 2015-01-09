node.set[:java][:jdk_version] = 7

include_recipe 'java'
include_recipe 'baragon::build'

%w(/etc/baragon /var/log/baragon).each do |dir|
  directory dir
end

unless node[:baragon][:mocking]
  node.set[:baragon][:zk_hosts] =
                    search(:node,
                           "chef_environment:#{node.chef_environment} AND " \
                           'roles:zookeeper').map do |n|
                      "#{n[:fqdn]}:#{node[:baragon][:zk_port]}"
                    end

  if node[:baragon][:zk_hosts].empty?
    fail 'Search returned no Zookeeper server nodes'
  end
end
