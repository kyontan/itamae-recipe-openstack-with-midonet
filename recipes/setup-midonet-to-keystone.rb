env = "OS_TOKEN=#{node[:keystone_admin_token]} OS_URL=http://#{node[:controller_node_ip]}:35357/v3 OS_IDENTITY_API_VERSION=3"

execute "Create the service entity for the midonet service" do
	command "#{env} openstack service create --name midonet --description \"MidoNet API Service\" midonet"
	not_if "#{env} openstack service list | grep midonet"
end
