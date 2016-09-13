package "midonet-cluster" do
	action :install
end

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
	user "root"

	nsdb_binds = node[:nsdb_ips].map{|x| "#{x}:2181"}.join(?,)
	command "cat <<EOF | mn-conf set -t default
zookeeper {
    zookeeper_hosts = \"#{nsdb_binds}\"
}
EOF
"
end

execute "Configure access to the NSDB (cassandra)" do
	user "root"

	nsdb_binds = node[:nsdb_ips].map{|x| "#{x}:2181"}.join(?,)
	command "cat <<EOF | mn-conf set -t default
cassandra {
    servers = \"#{node[:nsdb_ips].join(?,)}\"
}
EOF
"
end

execute "Configure Keystone access" do
	user "root"

	command "cat <<EOF | mn-conf set -t default
cluster.auth {
    provider_class = \"org.midonet.cluster.auth.keystone.KeystoneService\"
    admin_role = \"admin\"
    keystone.domain_id = \"\"
    keystone.domain_name = \"default\"
    keystone.tenant_name = \"admin\"
    keystone.admin_token = \"#{node[:keystone_admin_token]}\"
    keystone.host = #{node[:controller_node_ip]}
    keystone.port = 35357
}
EOF
"
end

service "midonet-cluster.service" do
  action [:enable, :restart]
end
