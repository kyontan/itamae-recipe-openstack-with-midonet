package "openstack-nova-compute" do
	action :install
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

		content.sub!(/^\#?rpc_backend ?=.*$/, "rpc_backend = rabbit")
		content.sub!(/^\#?rabbit_host ?=.*$/, "rabbit_host = #{node[:controller_node_ip]}")
		content.sub!(/^\#?rabbit_userid ?=.*$/, "rabbit_userid = openstack")
		content.sub!(/^\#?rabbit_password ?=.*$/, "rabbit_password = #{node[:rabbitmq_password]}")

		content.sub!(/^\#?auth_strategy ?=.*$/, "auth_strategy = keystone")

		content.sub!(/^\#?my_ip ?=.*$/, "my_ip = #{node[:ip_address]}")

		content.sub!(/^\#?use_neutron ?=.*$/, "use_neutron = True")
		content.sub!(/^\#?firewall_driver ?=.*$/, "firewall_driver = nova.virt.firewall.NoopFirewallDriver")

		regexp = /^\[vnc\](?:.+?\n)(?=\[.+?\])/m
		vnc_section = content.scan(regexp)[0]

		%w(enabled).each do |key|
			vnc_section.sub!(/^#?#{key} =.+\n/, "")
		end

		vnc_section += "enabled = True\n"

		content.sub!(regexp, vnc_section)


		content.sub!(/^\#?vncserver_listen ?=.*$/, "vncserver_listen = 0.0.0.0")
		content.sub!(/^\#?vncserver_proxyclient_address ?=.*$/, "vncserver_proxyclient_address = $my_ip")
		content.sub!(/^\#?novncproxy_base_url ?=.*$/, "novncproxy_base_url = http://#{node[:controller_node_ip]}:6080/vnc_auto.html")

		content.sub!(/^\#?api_servers ?=.*$/, "api_servers = http://#{node[:controller_node_ip]}:9292")
		content.sub!(/^\#?lock_path ?=.*$/, "lock_path = /var/lib/nova/tmp")
	end
end

file "/etc/nova/nova.conf" do
	action :edit
	# group "root"
	# user "nova"

	block do |content|
		content.sub!(/^\#?virt_type = .*$/, "virt_type = qemu")
	end

	only_if "egrep -c '(vmx|svm)' /proc/cpuinfo"
end

execute "Fix permission of /etc/nova/nova.conf" do
	command "chmod 640 /etc/nova/nova.conf"
end

%w(libvirtd openstack-nova-compute).each do |x|
	service "#{x}.service" do
		action [:enable, :restart]
	end
end
