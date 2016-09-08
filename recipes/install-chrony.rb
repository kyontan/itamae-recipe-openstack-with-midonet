package "chrony" do
	action :install	
end

file "/etc/chrony.conf" do
	action :edit

	block do |content|
		content.gsub!(/(?:^server .* iburst$)+/m, "server #{node[:ntp_server]} iburst")
		content.gsub!(/#allow 192.168\/16/, "allow #{node[:management_network_ip]}")
	end
end

service "chronyd.service" do
	action [:enable, :restart]
end

execute "check chronyc status" do
	command "true"
	print run_command("chronyc sources").stdout
end
