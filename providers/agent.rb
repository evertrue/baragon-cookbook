action :create do

  # Take the agent_yaml from node the attributes as a template and customize it
  agent_yaml = JSON.parse(node[:baragon][:agent_yaml].to_json)

  agent_yaml[:loadBalancerConfig][:name] = new_resource.group
  agent_yaml[:server][:connector][:port] = new_resource.port

  agent_root_path = "#{agent_yaml[:loadBalancerConfig][:rootPath]}/#{new_resource.group}"

  ["#{agent_root_path}/proxy",
   "#{agent_root_path}/upstreams"].each do |dir|
    directory dir do
      recursive true
    end
  end

  case node[:baragon][:install_type]
  when 'source'
    run_context.include_recipe 'baragon::build'

    remote_file "/usr/share/java/BaragonAgentService-#{node[:baragon][:version]}-shaded.jar" do
      action :create
      backup 5
      owner 'root'
      group 'root'
      mode 0644
      source "file://#{Chef::Config[:file_cache_path]}/Baragon/" \
             'BaragonAgentService/target/' \
             "BaragonAgentService-#{node[:baragon][:version]}-SNAPSHOT-shaded.jar"
    end
  when 'package'
    run_context.include_recipe 'maven'

    maven 'BaragonAgentService' do
      group_id 'com.hubspot'
      classifier 'shaded'
      version node[:baragon][:version]
      dest '/usr/share/java'
    end
  else
    fail "Unsupported install type: #{node[:baragon][:install_type]}"
  end

  # Set the zk Settings
  agent_yaml[:zookeeper][:quorum] = node[:baragon][:zk_hosts].join(',')
  agent_yaml[:zookeeper][:zkNamespace] = node[:baragon][:zk_namespace]

  if node[:nginx]
    unless node[:nginx][:binary]
      fail "attribute :binary not found in node[:nginx]: #{node[:nginx].inspect}"
    end
    agent_yaml[:loadBalancerConfig][:checkConfigCommand] = "#{node[:nginx][:binary]} -t"
    agent_yaml[:loadBalancerConfig][:reloadConfigCommand] = "#{node[:nginx][:binary]} -s reload"
  else
    agent_yaml[:loadBalancerConfig][:checkConfigCommand] = '/bin/true'
    agent_yaml[:loadBalancerConfig][:reloadConfigCommand] = '/bin/true'
  end

  agent_log =
    "#{node[:baragon][:agent_log_base]}/baragon_agent_#{new_resource.group}.log"

  agent_yaml[:loadBalancerConfig][:rootPath] = agent_root_path

  agent_yaml[:templates] = [node[:baragon][:proxy_template],
                             node[:baragon][:upstream_template]]

  file "/etc/baragon/agent-#{new_resource.group}.yml" do
    action :create
    owner 'root'
    group 'root'
    mode 0644
    content yaml_config(agent_yaml)
    notifies :restart, "service[baragon-agent-#{new_resource.group}]"
  end

  template "/etc/init/baragon-agent-#{new_resource.group}.conf" do
    source 'baragon-agent.init.erb'
    cookbook 'baragon'
    owner 'root'
    group 'root'
    mode 0644
    notifies :restart, "service[baragon-agent-#{new_resource.group}]"
    variables config_yaml: "/etc/baragon/agent-#{new_resource.group}.yml",
              agent_log: agent_log
  end

  logrotate_app "baragon_agent_#{new_resource.group}" do
    path agent_log
    size '100M'
    rotate 3
    create '644 root root'
    options %w(missingok copytruncate)
  end

  service "baragon-agent-#{new_resource.group}" do
    provider Chef::Provider::Service::Upstart
    supports status: true,
             restart: true
    action [:enable, :start]
  end
end

action :delete do
  fail 'Not Implemented'
end
