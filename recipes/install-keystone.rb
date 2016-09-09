execute "create keystone database" do
	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
		CREATE DATABASE keystone;\" || :"
end

execute "modify permission of user `keystone` (1)" do
	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
		GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
		IDENTIFIED BY '#{node[:keystone_db_password]}';\""
end

execute "modify permission of user `keystone` (2)" do
	command "mysql -uroot -p#{node[:db_root_password]} -e \" \
		GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
		IDENTIFIED BY '#{node[:keystone_db_password]}';\""
end

package "openstack-keystone" do
	action :install
end

package "httpd" do
	action :install
end

package "mod_wsgi" do
	action :install
end

directory "/etc/keystone" do
	action :create
	mode "0755"
end

execute "Workaround for `scp permission denied`" do
	command "chmod 666 /etc/keystone/keystone.conf"
end

file "/etc/keystone/keystone.conf" do
	action :edit
	# group "root"
	# user "keystone"

	block do |content|
		content.gsub!(/^\#?admin_token = .*$/, "admin_token = #{node[:keystone_admin_token]}")
		content.gsub!(/^\#?connection = .*$/, "connection = mysql+pymysql://keystone:#{node[:keystone_db_password]}@#{node[:controller_node_ip]}/keystone")
		content.gsub!(/^\#?provider = .*$/, "provider = fernet")
	end
end

execute "Fix permission of /etc/keystone/keystone.conf" do
	command "chmod 640 /etc/keystone/keystone.conf"
end

execute "Fix ownership of /etc/keystone/keystone.conf" do
	command "chown root:keystone /etc/keystone/keystone.conf"
end

directory "/etc/keystone" do
	action :create
	mode "0750"
end

remote_file "/tmp/keystone-setup.sh" do
	owner "root"
	user "root"
	mode "0777"
	source "../templates/keystone-setup.sh"
end

execute "keystone-setup.sh" do
	user "keystone"
	command "/tmp/keystone-setup.sh"
end

file "/tmp/keystone-setup.sh" do
	action :delete
end

# execute "Sync keystone-manage db" do
# 	user "keystone"
# 	command "keystone-manage db_sync"
# end

# execute "Initialize Fernet keys" do
# 	user "keystone"
# 	command "keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone"
# end

remote_file "/etc/httpd/conf.d/wsgi-keystone.conf" do
	owner "root"
	user "root"
	source "../templates/wsgi-keystone.conf"
end

service "httpd.service" do
	action [:enable, :restart]
end

env = "OS_TOKEN=#{node[:keystone_admin_token]} OS_URL=http://#{node[:controller_node_ip]}:35357/v3 OS_IDENTITY_API_VERSION=3"

# Create service (identity type only)
node[:services].select{|x| x[:type] == "identity" }.each do |service|
	execute "Create the #{service[:name]} service as #{service[:type]} service" do
		command "#{env} openstack service create --name #{service[:name]} --description \"#{service[:description]}\" #{service[:type]}"
		not_if "#{env} openstack service list | grep #{service[:name]}"
	end
end

interfaces = {
	public: 5000,
	internal: 5000,
	admin: 35357
}

interfaces.each do |interface, port|
	execute "Create Identity service API Endpoint (#{interface})" do
		command "#{env} openstack endpoint create --region #{node[:region_name]} identity #{interface} http://#{node[:controller_node_ip]}:#{port}/v3"
		not_if "#{env} openstack endpoint list | grep keystone | grep #{interface}"
	end
end
