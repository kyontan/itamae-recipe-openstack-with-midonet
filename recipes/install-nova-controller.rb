env = "OS_TOKEN=#{node[:keystone_admin_token]} OS_URL=http://#{node[:controller_node_ip]}:35357/v3 OS_IDENTITY_API_VERSION=3"

# execute "create nova_api database" do
# 	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
# 		CREATE DATABASE nova_api;\" || :"
# end

# execute "create nova database" do
# 	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
# 		CREATE DATABASE nova;\" || :"
# end

# execute "modify permission of user `nova` (1)" do
# 	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
# 		GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
# 		IDENTIFIED BY '#{node[:nova_db_password]}';\""
# end

# execute "modify permission of user `nova` (2)" do
# 	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
# 		GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
# 		IDENTIFIED BY '#{node[:nova_db_password]}';\""
# end

# execute "modify permission of user `nova` (3)" do
# 	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
# 		GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
# 		IDENTIFIED BY '#{node[:nova_db_password]}';\""
# end

# execute "modify permission of user `nova` (4)" do
# 	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
# 		GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
# 		IDENTIFIED BY '#{node[:nova_db_password]}';\""
# end

# interfaces = {
# 	public: 8774,
# 	internal: 8774,
# 	admin: 8774
# }

# interfaces.each do |interface, port|
# 	execute "Create Identity service API Endpoint (#{interface})" do
# 		command "#{env} openstack endpoint create --region #{node[:region_name]} compute #{interface} http://#{node[:controller_node_ip]}:#{port}/v2.1/%\\(tenant_id\\)s"
# 		not_if "#{env} openstack endpoint list | grep nova | grep #{interface}"
# 	end
# end

%w(api conductor console novncproxy scheduler).each do |x|
	package "openstack-nova-#{x}" do
		action :install
	end	
end

execute "Workaround for `scp permission denied`" do
	command "chmod 666 /etc/nova/nova.conf"
end

file "/etc/nova/nova.conf" do
	action :edit
	# group "root"
	# user "nova"

	block do |content|

		content.sub!(/^\#?auth_uri ?=.*$/, "auth_uri = http://#{node[:controller_node_ip]}:5000")
		content.sub!(/^\#?memcached_servers ?=.*$/, "memcached_servers = #{node[:controller_node_ip]}:11211")
		
		regexp = /^\[keystone_authtoken\](?:.+?\n)(?=\[.+?\])/m
		keystone_authtoken_section = content.scan(regexp)[0]

		%w(auth_type auth_url project_domain_name user_domain_name project_name username password).each do |key|
			keystone_authtoken_section.sub!(/^#?#{key} =.+\n/, "")
		end

		keystone_authtoken_section += "auth_type = password\n"
		keystone_authtoken_section += "auth_url = http://#{node[:controller_node_ip]}:35357\n"
		keystone_authtoken_section += "project_domain_name = default\n"
		keystone_authtoken_section += "user_domain_name = default\n"
		keystone_authtoken_section += "project_name = service\n"
		keystone_authtoken_section += "username = nova\n"
		keystone_authtoken_section += "password = #{node[:nova_admin_password]}\n"

		content.sub!(regexp, keystone_authtoken_section)

		content.sub!(/^\#?enabled_apis ?=.*$/, "enabled_apis = osapi_compute,metadata")
		content.sub!(/^\#?connection=mysql:\/\/nova:nova@localhost\/nova$/, "connection = mysql+pymysql://nova:#{node[:nova_db_password]}@#{node[:controller_node_ip]}/nova_api")
		content.sub!(/^\#?connection=<None>$/, "connection = mysql+pymysql://nova:#{node[:nova_db_password]}@#{node[:controller_node_ip]}/nova")
		content.sub!(/^\#?rpc_backend ?=.*$/, "rpc_backend = rabbit")
		content.sub!(/^\#?rabbit_host ?=.*$/, "rabbit_host = #{node[:controller_node_ip]}")
		content.sub!(/^\#?rabbit_userid ?=.*$/, "rabbit_userid = rabbit")
		content.sub!(/^\#?rabbit_password ?=.*$/, "rabbit_password = #{node[:rabbitmq_password]}")

		content.sub!(/^\#?auth_strategy ?=.*$/, "auth_strategy = keystone")

		content.sub!(/^\#?use_neutron ?=.*$/, "use_neutron = True")
		content.sub!(/^\#?firewall_driver ?=.*$/, "firewall_driver = nova.virt.firewall.NoopFirewallDriver")
		content.sub!(/^\#?vncserver_listen ?=.*$/, "vncserver_listen = $my_ip")
		content.sub!(/^\#?vncserver_proxyclient_address ?=.*$/, "vncserver_proxyclient_address = $my_ip")
		content.sub!(/^\#?api_servers ?=.*$/, "api_servers = http://#{node[:controller_node_ip]}:9292")
		content.sub!(/^\#?lock_path ?=.*$/, "lock_path = /var/lib/nova/tmp")
	end
end

execute "Fix permission of /etc/nova/nova.conf" do
	command "chmod 640 /etc/nova/nova.conf"
end

remote_file "/tmp/nova-setup.sh" do
	owner "root"
	user "root"
	mode "0777"
	source "../templates/nova-setup.sh"
end

execute "nova-setup.sh" do
	user "nova"
	command "/tmp/nova-setup.sh"
end

file "/tmp/nova-setup.sh" do
	action :delete
end


%w(api consoleauth scheduler conductor novncproxy).each do |x|
	service "openstack-nova-#{x}.service" do
		action [:enable, :restart]
	end
end
