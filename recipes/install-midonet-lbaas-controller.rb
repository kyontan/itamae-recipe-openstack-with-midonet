package "python-neutron-lbaas" do
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
		value = "lbaas"

		if /^service_plugins ?=.*#{value}/ === section
		elsif /^service_plugins ?=.+/ === section
			section.sub!(/^service_plugins ?=.+/, "\\0,#{value}")
		else
			section.sub!(/^#?service_plugins ?=.+/, "service_plugins = #{value}")
		end

		content.sub!(regexp, section)

		# ---------

		regexp = /^\[service_providers\](?:.+?\n)(?=\Z|\[.+?\])/m
		section = content.scan(regexp)[0]

		if section
			section.sub!(/^#?service_provider =.+\n/, "")
			section << "service_provider = LOADBALANCER:Midonet:midonet.neutron.services.loadbalancer.driver.MidonetLoadbalancerDriver:default\n"
			content.sub!(regexp, section)
		else
			content << "[service_providers]\n"
			content << "service_provider = LOADBALANCER:Midonet:midonet.neutron.services.loadbalancer.driver.MidonetLoadbalancerDriver:default\n"
		end
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
		content.sub(/^(\s*'enable_lb':\s*)False\s*,/, "\\1True,")
	end
end

execute "Fix permission of /etc/openstack-dashboard/local_settings" do
	command "chmod 640 /etc/openstack-dashboard/local_settings"
end

directory "/etc/openstack-dashboard" do
	action :create
	mode "0750"
end
