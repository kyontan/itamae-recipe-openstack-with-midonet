package "python-midonetclient" do
	action :install
end


template "/root/.midonetrc" do
	source "../templates/midonetrc.erb"
	admin_pass = node[:users].find{|x| x[:name] == "admin" }[:password]
	variables(controller_node_ip: node[:controller_node_ip], admin_pass: admin_pass)

	owner "root"
	group "root"
	mode "0700"
end
