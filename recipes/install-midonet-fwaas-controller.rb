package "python-neutron-fwaas" do
	action :install
end

execute "Workaround for `scp permission denied`" do
	command "chmod 666 /etc/neutron/neutron.conf"
end

file "/etc/neutron/neutron.conf" do
	action :edit
	# group "root"
	# user "neutron"

	block do |content|
		regexp = /^\[DEFAULT\](?:.+?\n)(?=\[.+?\])/m
		section = content.scan(regexp)[0]
		value = "midonet.neutron.services.firewall.plugin.MidonetFirewallPlugin"

		if /^service_plugins ?=.*#{value}/ === section
		elsif /^service_plugins ?=.*/ === section
			section.sub!(/^service_plugins ?=.*/, "\\0,#{value}")
		else
			section.sub!(/^#?service_plugins ?=.*/, "service_plugins = #{value}")
		end

		content.sub!(regexp, section)
	end
end

execute "Fix permission of /etc/neutron/neutron.conf" do
	command "chmod 640 /etc/neutron/neutron.conf"
end

directory "/etc/openstack-dashboard" do
	action :create
	mode "0755"
end

execute "Workaround for `scp permission denied`" do
	command "chmod 666 /etc/openstack-dashboard/local_settings"
end

file "/etc/openstack-dashboard/local_settings" do
	action :edit
	# group "root"
	# user "apache"

	block do |content|
		content.sub(/^(\s*'enable_firewall':\s*)False\s*,/, "\\1True,")
	end
end

execute "Fix permission of /etc/openstack-dashboard/local_settings" do
	command "chmod 640 /etc/openstack-dashboard/local_settings"
end

directory "/etc/openstack-dashboard" do
	action :create
	mode "0750"
end
