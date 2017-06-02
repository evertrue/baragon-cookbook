Chef::Resource.send(:include, Baragon::Helpers)

ruby_block 'create test zk request' do
  block { create_test_zk_request }
  action :nothing
  notifies :restart, 'service[nginx]', :before
  subscribes :run, 'service[baragon-server]'
end
