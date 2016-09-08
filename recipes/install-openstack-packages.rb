package "centos-release-openstack-mitaka" do
	action :install
end

execute "upgrade yum repositories" do
	command "yum -y upgrade"
end

package "python-openstackclient" do
	action :install
end

package "openstack-selinux" do
	action :install
end
