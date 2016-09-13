package "mariadb" do
	action :install
end

package "mariadb-server" do
	action :install
end

package "python2-PyMySQL" do
	action :install
end

template "/etc/my.cnf.d/openstack.cnf" do
	source "../templates/my.cnf.erb"
	variables(controller_node_ip: node[:controller_node_ip])

	owner "root"
	group "root"
	mode "0644"
end

service "mariadb.service" do
	action [:enable, :restart]
end

template "/tmp/automate-mysql-secure-install.sh" do
	source "../templates/automate-mysql-secure-install.sh.erb"
	variables(db_root_password: node[:db_root_password])

	owner "root"
	group "root"
	mode "0700"
end

execute "Execute mysql-secure-install" do
	command "sh /tmp/automate-mysql-secure-install.sh"
end

file "/tmp/automate-mysql-secure-install.sh" do
	action :delete
end

service "mariadb.service" do
	action [:restart]
end
