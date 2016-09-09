env = "OS_TOKEN=#{node[:keystone_admin_token]} OS_URL=http://#{node[:controller_node_ip]}:35357/v3 OS_IDENTITY_API_VERSION=3"

node[:services].select{|x| x[:type] != "identity" }.each do |service|
	execute "Create the #{service[:name]} service as #{service[:type]} service" do
		command "#{env} openstack service create --name #{service[:name]} --description \"#{service[:description]}\" #{service[:type]}"
		not_if "#{env} openstack service list | grep #{service[:name]}"
	end
end

node[:domains].each do |domain|
	execute "Create #{domain[:name]} domain" do
		command "#{env} openstack domain create --description \"#{domain[:description]}\" #{domain[:name]}"
		not_if "#{env} openstack domain list | grep #{domain[:name]}"
	end
end

node[:projects].each do |project|
	execute "Create #{project[:name]} project" do
		command "#{env} openstack project create --domain #{project[:domain]} --description \"#{project[:description]}\" #{project[:name]}"
		not_if "#{env} openstack project list | grep #{project[:name]}"
	end
end

node[:users].each do |user|
	execute "Create #{user[:name]} user" do
		command "#{env} openstack user create --domain #{user[:domain]} --password \"#{user[:password]}\" #{user[:name]}"
		not_if "#{env} openstack user list | grep #{user[:name]}"
	end
end

node[:roles].each do |role|
	execute "Create #{role[:name]} role" do
		command "#{env} openstack role create #{role[:name]}"
		not_if "#{env} openstack role list | grep #{role[:name]}"
	end

	execute "Create #{role[:name]} role" do
		command "#{env} openstack role add --project #{role[:project]} --user \"#{role[:user]}\" #{role[:name]}"
		not_if "#{env} openstack role assignment list --project #{role[:project]} --user #{role[:user]} --role #{role[:name]} | grep #{role[:name]}"
	end
end
