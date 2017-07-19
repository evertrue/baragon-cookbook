Chef::Resource.send(:include, Baragon::Helpers)

cookbook_file '/etc/nginx/conf.d/baragon.conf' do
  action :nothing
  subscribes :create, 'ruby_block[create test zk request]'
  notifies :restart, 'service[nginx]', :delayed
end

ruby_block 'create test zk request' do
  block { create_test_zk_request }
  action :nothing
  notifies :restart, 'service[nginx]', :before
  subscribes :run, 'service[baragon-server]'
end

package 'lighttpd'

service 'lighttpd' do
  supports restart: true
  action :enable
end

cookbook_file '/etc/lighttpd/lighttpd.conf' do
  notifies :restart, 'service[lighttpd]'
end

directory '/var/www/html/testbasepath1' do
  recursive true
end

file '/var/www/html/testbasepath1/index.html' do
  content "<h1>Hello World!</h1>\n"
end
