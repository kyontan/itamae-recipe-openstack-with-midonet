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

		%w(url auth_url auth_type project_domain_name user_domain_name region_name project_name username password).each do |key|
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

		content.sub!(regexp, neutron_section)
	end
end

execute "Fix permission of /etc/nova/nova.conf" do
	command "chmod 640 /etc/nova/nova.conf"
end

service "openstack-nova-compute.service" do
	action [:enable, :restart]
end
