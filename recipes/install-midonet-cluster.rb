package "midonet-cluster" do
	action :install
end

require "yaml"

file "/etc/midonet/midonet.conf" do
	action :edit
	# group "root"
	# user "root"

	block do |content|
		nsdb_binds = node[:nsdb_ips].map{|x| "#{x}:2181"}.join(?,)
		content.sub!(/^\#?zookeeper_hosts = .*$/, "zookeeper_hosts = #{nsdb_binds}")
	end
end

execute "Configure access to the NSDB (zookeeper)" do
	nsdb_binds = node[:nsdb_ips].map{|x| "#{x}:2181"}.join(?,)

	command "cat <<EOF | mn-conf set -t default
zookeeper {
    zookeeper_hosts = \"#{nsdb_binds}\"
}
EOF
"
  not_if "mn-conf get zookeeper"
end

execute "Configure access to the NSDB (cassandra)" do
	nsdb_binds = node[:nsdb_ips].map{|x| "#{x}:2181"}.join(?,)

	command "cat <<EOF | mn-conf set -t default
cassandra {
    servers = \"#{node[:nsdb_ips].join(?,)}\"
}
EOF
"
  not_if "mn-conf get cassandra"
end

execute "Configure Keystone access" do
	admin_pass = node[:users].find{|x| x[:name] == "admin" }[:password]

	command "cat <<EOF | mn-conf set -t default
cluster.auth {
    provider_class = \"org.midonet.cluster.auth.keystone.KeystoneService\"
    admin_role = \"admin\"
    keystone.tenant_name = \"admin\"
    keystone.admin_token = \"#{admin_pass}\"
    keystone.host = #{node[:controller_node_ip]}
    keystone.port = 35357
}
EOF
"
  not_if "mn-conf get cluster.auth"
end

service "midonet-cluster.service" do
  action [:enable, :restart]
end
