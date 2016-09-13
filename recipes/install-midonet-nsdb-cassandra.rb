%w(java-1.8.0-openjdk-headless dsc22).each do |x|
	package x do
		action :install
	end
end

require "yaml"

file "/etc/init.d/cassandra" do
	action :edit
	# group "root"
	# user "root"

	block do |content|
		addition = ["mkdir -p /var/run/cassandra", "chown cassandra:cassandra /var/run/cassandra"]
		content.sub!(/(?<="Starting Cassandra: ")(?:\n??.*??)(\n\s*?)(?=su )/m, "\\1#{addition.join("\\1")}\\1")
	end
end

execute "systemctl daemon-reload" do
	command "systemctl daemon-reload"
end

service "cassandra.service" do
	action [:enable, :restart]
end
