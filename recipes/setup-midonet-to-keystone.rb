execute "Create the service entity for the midonet service" do
	command "#{env} openstack service create --name midonet --description \"MidoNet API Service\" midonet"
	not_if "#{env} openstack service list | grep midonet"
end

