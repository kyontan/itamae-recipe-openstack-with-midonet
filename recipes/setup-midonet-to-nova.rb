directory "/etc/libvirt" do
	action :create
	mode "0755"
end

execute "Workaround for `scp permission denied`" do
	command "chmod 666 /etc/libvirt/qemu.conf"
end

file "/etc/libvirt/qemu.conf" do
	action :edit
	# group "root"
	# user "root"

	block do |content|
		content.sub!(/^\#?user ?=.*$/, "user = \"root\"")
		content.sub!(/^\#?group ?=.*$/, "group = \"root\"")

		content.sub!(/^\#?cgroup_device_acl ?=\s+?\[.*?\]/m, <<EOF)
cgroup_device_acl = [
    "/dev/null", "/dev/full", "/dev/zero",
    "/dev/random", "/dev/urandom",
    "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
    "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
    "/dev/net/tun"
]
EOF

	end
end

execute "Fix permission of /etc/libvirt/qemu.conf" do
	command "chmod 644 /etc/libvirt/qemu.conf"
end

directory "/etc/keystone" do
	action :create
	mode "0700"
end

service "libvirtd.service" do
	action [:enable, :restart]
end

package "openstack-nova-network" do
	action :install
end

service "openstack-nova-network.service" do
	action :disable
end

service "openstack-nova-compute.service" do
	action [:enable, :restart]
end
