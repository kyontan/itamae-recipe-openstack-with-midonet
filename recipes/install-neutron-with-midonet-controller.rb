env = "OS_TOKEN=#{node[:keystone_admin_token]} OS_URL=http://#{node[:controller_node_ip]}:35357/v3 OS_IDENTITY_API_VERSION=3"

execute "create neutron database" do
	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
		CREATE DATABASE neutron;\" || :"
end

execute "modify permission of user `neutron` (1)" do
	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
		GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
		IDENTIFIED BY '#{node[:neutron_db_password]}';\""
end

execute "modify permission of user `neutron` (2)" do
	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
		GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
		IDENTIFIED BY '#{node[:neutron_db_password]}';\""
end

interfaces = {
	public: 9696,
	internal: 9696,
	admin: 9696
}

interfaces.each do |interface, port|
	execute "Create Identity service API Endpoint (#{interface})" do
		command "#{env} openstack endpoint create --region #{node[:region_name]} network #{interface} http://#{node[:controller_node_ip]}:#{port}"
		not_if "#{env} openstack endpoint list | grep neutron | grep #{interface}"
	end
end

%w(openstack-neutron python-networking-midonet python-neutronclient).each do |x|
	package x do
		action :install
	end
end

package "openstack-neutron-ml2" do
	action :remove
end

execute "Workaround for `scp permission denied`" do
	command "chmod 666 /etc/neutron/neutron.conf"
end

file "/etc/neutron/neutron.conf" do
	action :edit
	# group "root"
	# user "neutron"

	block do |content|
		regexp = /^\[DEFAULT\](?:.+?\n)(?=\[.+?\])/m
		section = content.scan(regexp)[0]
		%w(core_plugin service_plugins dhcp_agent_notification allow_overlapping_ips rpc_backend auth_strategy notify_nova_on_port_status_changes notify_nova_on_port_data_changes nova_url).each do |key|
			section.sub!(/^#?#{key} =.+\n/, "")
		end

		section << "core_plugin = midonet.neutron.plugin_v2.MidonetPluginV2\n"
		section << "service_plugins = midonet.neutron.services.l3.l3_midonet.MidonetL3ServicePlugin\n"
		section << "dhcp_agent_notification = False\n"
		section << "allow_overlapping_ips = True\n"
		section << "rpc_backend = rabbit\n"
		section << "auth_strategy = keystone\n"
		section << "notify_nova_on_port_status_changes = True\n"
		section << "notify_nova_on_port_data_changes = True\n"
		section << "nova_url = http://#{node[:controller_node_ip]}:8774/v2.1\n"

		content.sub!(regexp, section)

		# ---------

		regexp = /^\[database\](?:.+?\n)(?=\[.+?\])/m
		section = content.scan(regexp)[0]
		section.sub!(/^#?connection =.+\n/, "")

		section << "connection = mysql+pymysql://neutron:#{node[:neutron_db_password]}@#{node[:controller_node_ip]}/neutron\n"

		content.sub!(regexp, section)

		# ---------

		regexp = /^\[oslo_messaging_rabbit\](?:.+?\n)(?=\[.+?\])/m
		section = content.scan(regexp)[0]
		%w(rabbit_host rabbit_userid rabbit_password).each do |key|
			section.sub!(/^#?#{key} =.+\n/, "")
		end

		section << "rabbit_host = #{node[:controller_node_ip]}\n"
		section << "rabbit_userid = openstack\n"
		section << "rabbit_password = #{node[:rabbitmq_password]}\n"

		content.sub!(regexp, section)

		# ---------

		regexp = /^\[keystone_authtoken\](?:.+?\n)(?=\[.+?\])/m
		section = content.scan(regexp)[0]
		%w(auth_uri auth_url memcached_servers auth_plugin project_domain_id user_domain_id project_name username password).each do |key|
			section.sub!(/^#?#{key} =.+\n/, "")
		end

		section << "auth_uri = http://#{node[:controller_node_ip]}:5000\n"
		section << "auth_url = http://#{node[:controller_node_ip]}:35357\n"
		section << "memcached_servers = #{node[:controller_node_ip]}:11211\n"
		section << "auth_plugin = password\n"
		section << "project_domain_id = default\n"
		section << "user_domain_id = default\n"
		section << "project_name = service\n"
		section << "username = neutron\n"
		section << "password = #{node[:neutron_admin_password]}\n"

		content.sub!(regexp, section)

		# ---------

		regexp = /^\[nova\](?:.+?\n)(?=\[.+?\])/m
		section = content.scan(regexp)[0]
		%w(auth_url auth_plugin project_domain_id user_domain_id region_name project_name username password).each do |key|
			section.sub!(/^#?#{key} =.+\n/, "")
		end

		section << "auth_url = http://#{node[:controller_node_ip]}:35357\n"
		section << "auth_plugin = password\n"
		section << "project_domain_id = default\n"
		section << "user_domain_id = default\n"
		section << "region_name = #{node[:region_name]}\n"
		section << "project_name = service\n"
		section << "username = nova\n"
		section << "password = #{node[:nova_admin_password]}\n"

		content.sub!(regexp, section)

		# ---------

		regexp = /^\[oslo_concurrency\](?:.+?\n)(?=\[.+?\])/m
		section = content.scan(regexp)[0]
		section.sub!(/^#?lock_path =.+\n/, "")

		section << "lock_path = /var/lib/neutron/tmp\n"

		content.sub!(regexp, section)
	end
end

execute "Fix permission of /etc/neutron/neutron.conf" do
	command "chmod 640 /etc/neutron/neutron.conf"
end

directory "/etc/neutron/plugins/midonet" do
	action :create
	group "root"
	owner "root"
end

template "/etc/neutron/plugins/midonet/midonet.ini" do
	action :create
	source "../templates/midonet.ini.erb"
	variables(controller_node_ip: node[:controller_node_ip], midonet_password: node[:midonet_password])

	owner "root"
	group "root"
	mode "0644"
end

link "/etc/neutron/plugin.ini" do
	to "/etc/neutron/plugins/midonet/midonet.ini"
end

execute "Workaround for `scp permission denied`" do
	command "chmod 666 /etc/nova/nova.conf"
end

file "/etc/nova/nova.conf" do
	action :edit
	# group "root"
	# user "nova"

	block do |content|
		regexp = /^\[neutron\](?:.+?\n)(?=\[.+?\])/m
		neutron_section = content.scan(regexp)[0]

		%w(url auth_url auth_type project_domain_name user_domain_name region_name project_name username password service_metadata_proxy metadata_proxy_shared_secret).each do |key|
			neutron_section.sub!(/^#?#{key} ?=.+\n/, "")
		end

		neutron_section << "url = http://#{node[:controller_node_ip]}:9696\n"
		neutron_section << "auth_url = http://#{node[:controller_node_ip]}:35357\n"
		neutron_section << "auth_type = password\n"
		neutron_section << "project_domain_name = default\n"
		neutron_section << "user_domain_name = default\n"
		neutron_section << "region_name = #{node[:region_name]}\n"
		neutron_section << "project_name = service\n"
		neutron_section << "username = neutron\n"
		neutron_section << "password = #{node[:neutron_admin_password]}\n"

		neutron_section << "service_metadata_proxy = True\n"
		neutron_section << "metadata_proxy_shared_secret = METADATA_SECRET\n"

		content.sub!(regexp, neutron_section)
	end
end

execute "Fix permission of /etc/nova/nova.conf" do
	command "chmod 640 /etc/nova/nova.conf"
end

remote_file "/tmp/neutron-and-midonet-setup.sh" do
	owner "root"
	user "root"
	mode "0777"
	source "../templates/neutron-and-midonet-setup.sh"
end

execute "neutron-and-midonet-setup.sh" do
	user "neutron"
	command "/tmp/neutron-and-midonet-setup.sh"
end

file "/tmp/neutron-and-midonet-setup.sh" do
	action :delete
end

%w(openstack-nova-api neutron-server).each do |x|
	service "#{x}.service" do
		action [:enable, :restart]
	end
end
