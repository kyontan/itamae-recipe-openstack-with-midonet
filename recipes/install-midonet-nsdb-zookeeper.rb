%w(java-1.8.0-openjdk-headless zookeeper zkdump nmap-ncat).each do |x|
	package x do
		action :install
	end
end

file "/etc/zookeeper/zoo.cfg" do
	action :edit
	# group "root"
	# user "root"

	block do |content|
		content.gsub!(/^#?server\.\d+ =.+\n/, "")
		node[:nsdb_ips].each.with_index do |x, i|
			content << "server.#{i+1} = #{x}:2888:3888\n"
		end

		%w(autopurge.snapRetainCount autopurge.purgeInterval).each do |key|
			content.sub!(/^#?#{key} =.+\n/, "")
		end

		content << "autopurge.snapRetainCount = 10\n"
		content << "autopurge.purgeInterval = 12\n"
	end
end

directory "/var/lib/zookeeper/data" do
	owner "zookeeper"
	group "zookeeper"
end

execute "set zookeeper host id" do
	user "root"
	command "echo #{node[:nsdb_node_id]} > /var/lib/zookeeper/data/myid"
end

directory "/usr/java/default/bin/" do
	owner "root"
	group "root"
  action :create
end

link "/usr/java/default/bin/java" do
  action :create
	to "/usr/lib/jvm/jre-1.8.0-openjdk/bin/java"
end

service "zookeeper.service" do
  action [:enable, :restart]
end
