package "memcached" do
	action :install
end

package "python-memcached" do
	action :install
end

service "memcached.service" do
	action [:enable, :restart]
end
