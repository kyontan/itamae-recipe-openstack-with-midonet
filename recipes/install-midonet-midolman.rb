%w(java-1.8.0-openjdk-headless midolman).each do |x|
	package x do
		action :install
	end
end

file "/etc/midolman/midolman.conf" do
	action :edit

	block do |content|
		nsdb_binds = node[:nsdb_ips].map{|x| "#{x}:2181"}.join(?,)
		content.sub!(/^#?zookeeper_hosts ?=.*$/, "zookeeper_hosts = #{nsdb_binds}")
	end
end

execute "configure the Midolman resource template" do
	user "root"
	command "mn-conf template-set -h local -t #{node[:midonet][:resource_template_name]}"
end

execute "configure the JVM resource template" do
	user "root"
	command "cp /etc/midolman/#{node[:midonet][:midolman_jvm_resource_template]} /etc/midolman/midolman-env.sh"
end

execute "configure MidoNet Metadata Proxy (agent.openstack.metadata.nova_metadata_url)" do
  user "root"
	command "echo \"agent.openstack.metadata.nova_metadata_url : \\\"http://#{node[:controller_node_ip]}:8775\\\"\" | mn-conf set -t default"
	not_if "mn-conf get agent.openstack.metadata.nova_metadata_url"
end

execute "configure MidoNet Metadata Proxy (agent.openstack.metadata.shared_secret)" do
  user "root"
	command "echo \"agent.openstack.metadata.shared_secret : #{node[:neutron_metadata_proxy_shared_secret]}\" | mn-conf set -t default"
	not_if "mn-conf get agent.openstack.metadata.shared_secret"
end

execute "configure MidoNet Metadata Proxy (agent.openstack.metadata.enabled)" do
  user "root"
	command "echo \"agent.openstack.metadata.enabled : true\" | mn-conf set -t default"
	not_if "mn-conf get agent.openstack.metadata.enabled"
end

service "midolman.service" do
	action [:enable, :restart]
end
