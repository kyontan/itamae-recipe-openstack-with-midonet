package "openstack-dashboard" do
	action :install
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
		content.sub!(/^CACHES ?= \{.*?\{.*?\}.*?\}/m, <<"EOF".strip)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '#{node[:controller_node_ip]}:11211',
    },
}
EOF

		content.sub!(/^\#?OPENSTACK_API_VERSIONS ?= \{.*?\}/m, <<EOF.strip)
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
EOF

		%w(OPENSTACK_HOST ALLOWED_HOSTS OPENSTACK_KEYSTONE_URL OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT OPENSTACK_KEYSTONE_DEFAULT_DOMAIN OPENSTACK_KEYSTONE_DEFAULT_ROLE TIME_ZONE).each do |key|
			content.sub!(/^#?#{key} =.+\n/, "")
		end

		content << "OPENSTACK_HOST = \"#{node[:controller_node_ip]}\"\n"
		content << "ALLOWED_HOSTS = ['*', ]\n"
		content << "OPENSTACK_KEYSTONE_URL = \"http://%s:5000/v3\" % OPENSTACK_HOST\n"
		content << "OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True\n"
		content << "OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = \"default\"\n"
		content << "OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\"\n"
		content << "TIME_ZONE = \"#{node[:time_zone]}\"\n"
	end
end

execute "Fix permission of /etc/openstack-dashboard/local_settings" do
	command "chmod 640 /etc/openstack-dashboard/local_settings"
end

directory "/etc/openstack-dashboard" do
	action :create
	mode "0750"
end

%w(httpd memcached).each do |x|
	service "#{x}.service" do
		action :restart
	end
end
