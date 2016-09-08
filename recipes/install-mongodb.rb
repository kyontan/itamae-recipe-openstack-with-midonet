package "mongodb-server" do
	action :install
end

package "mongodb" do
	action :install
end

file "/etc/mongod.conf" do
	action :edit

	block do |content|
		content.gsub!("bind_ip = 127.0.0.1", "bind_ip = #{node[:controller_node_ip]}")
	end
end

service "mongod.service" do
	action [:enable, :restart]
end
