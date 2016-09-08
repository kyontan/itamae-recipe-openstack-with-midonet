package "rabbitmq-server" do
	action :install
end

service "rabbitmq-server.service" do
	action [:enable, :restart]
end

execute "add openstack user to rabbitmq-server" do
	command "rabbitmqctl add_user openstack #{node[:rabbitmq_password]}"
end

execute "edit permission of openstack user to rabbitmq-server" do
	command "rabbitmqctl set_permissions openstack \".*\" \".*\" \".*\""
end
