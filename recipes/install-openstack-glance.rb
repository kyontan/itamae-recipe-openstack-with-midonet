env = "OS_TOKEN=#{node[:keystone_admin_token]} OS_URL=http://#{node[:controller_node_ip]}:35357/v3 OS_IDENTITY_API_VERSION=3"

execute "create glance database" do
	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
		CREATE DATABASE glance;\" || :"
end

execute "modify permission of user `glance` (1)" do
	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
		GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
		IDENTIFIED BY '#{node[:glance_db_password]}';\""
end

execute "modify permission of user `glance` (2)" do
	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
		GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
		IDENTIFIED BY '#{node[:glance_db_password]}';\""
end

interfaces = {
	public: 9292,
	internal: 9292,
	admin: 9292
}

interfaces.each do |interface, port|
	execute "Create Identity service API Endpoint (#{interface})" do
		command "#{env} openstack endpoint create --region #{node[:region_name]} image #{interface} http://#{node[:controller_node_ip]}:#{port}/v3"
		not_if "#{env} openstack endpoint list | grep glance | grep #{interface}"
	end
end

package "openstack-glance" do
	action :install
end

execute "Workaround for `scp permission denied`" do
	command "chmod 666 /etc/glance/glance-api.conf"
end

file "/etc/glance/glance-api.conf" do
	action :edit
	# group "root"
	# user "glance"

	block do |content|
		content.sub!(/^\#?connection = .*$/, "connection = mysql+pymysql://glance:#{node[:glance_db_password]}@#{node[:controller_node_ip]}/glance")

		content.sub!(/^\#?auth_uri = .*$/, "auth_uri = http://#{node[:controller_node_ip]}:5000")
		content.sub!(/^\#?memcached_servers = .*$/, "memcached_servers = #{node[:controller_node_ip]}:11211")

		regexp = /^\[keystone_authtoken\](?:.+?\n)(?=\[.+?\])/m
		keystone_authtoken_section = content.scan(regexp)[0]

		%w(auth_url project_domain_name user_domain_name project_name username password).each do |key|
			keystone_authtoken_section.sub!(/^#?#{key} =.+\n/, "")
		end

		keystone_authtoken_section << "auth_url = http://#{node[:controller_node_ip]}:35357\n"
		keystone_authtoken_section << "project_domain_name = default\n"
		keystone_authtoken_section << "user_domain_name = default\n"
		keystone_authtoken_section << "project_name = service\n"
		keystone_authtoken_section << "username = glance\n"
		keystone_authtoken_section << "password = node[:glance_admin_password]\n"

		content.sub!(regexp, keystone_authtoken_section)

		content.sub!(/^\#?flavor = .*$/, "flavor = keystone")

		content.sub!(/^\#?stores = .*$/, "stores = file,http")
		content.sub!(/default_store = .*(?:\nfilesystem_store_datadir.*)?/, "default_store = file\nfilesystem_store_datadir = /var/lib/glance/images/")
	end
end

execute "Fix permission of /etc/glance/glance-api.conf" do
	command "chmod 640 /etc/glance/glance-api.conf"
end

execute "Workaround for `scp permission denied`" do
	command "chmod 666 /etc/glance/glance-registry.conf"
end

file "/etc/glance/glance-registry.conf" do
	action :edit
	# group "root"
	# user "glance"

	block do |content|
		content.sub!(/^\#?connection = .*$/, "connection = mysql+pymysql://glance:#{node[:glance_db_password]}@#{node[:controller_node_ip]}/glance")

		content.sub!(/^(?:\#?auth_uri = .*\n)+$/, [5000, 35357].map{|port| "auth_uri = http://#{node[:controller_node_ip]}:#{port}\n" }.join)
		content.sub!(/^\#?memcached_servers = .*$/, "memcached_servers = #{node[:controller_node_ip]}:11211")

		regexp = /^\[keystone_authtoken\](?:.+?\n)(?=\[.+?\])/m
		keystone_authtoken_section = content.scan(regexp)[0]

		%w(project_domain_name user_domain_name project_name username password).each do |key|
			keystone_authtoken_section.sub!(/^#?#{key} =.+\n/, "")
		end

		keystone_authtoken_section << "project_domain_name = default\n"
		keystone_authtoken_section << "user_domain_name = default\n"
		keystone_authtoken_section << "project_name = service\n"
		keystone_authtoken_section << "username = glance\n"
		keystone_authtoken_section << "password = #{node[:glance_admin_password]}\n"

		content.sub!(regexp, keystone_authtoken_section)
	end
end

execute "Fix permission of /etc/glance/glance-registry.conf" do
	command "chmod 640 /etc/glance/glance-api.conf"
end

remote_file "/tmp/glance-setup.sh" do
	owner "root"
	user "root"
	mode "0777"
	source "../templates/glance-setup.sh"
end

execute "glance-setup.sh" do
	user "glance"
	command "/tmp/glance-setup.sh"
end

file "/tmp/glance-setup.sh" do
	action :delete
end

service "openstack-glance-api.service" do
	action [:enable, :restart]
end
