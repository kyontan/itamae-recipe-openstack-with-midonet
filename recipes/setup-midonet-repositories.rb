# package "subscription-manager" do
# 	action :install
# end

# execute "Enable Red Hat base repository" do
# 	user "root"
# 	command "subscription-manager repos --enable=rhel-7-server-rpms"
# end

# execute "Enable additional Red Hat repositories (1)" do
# 	user "root"
# 	command "subscription-manager repos --enable=rhel-7-server-rpms"
# end

# execute "Enable additional Red Hat repositories (2)" do
# 	user "root"
# 	command "subscription-manager repos --enable=rhel-7-server-optional-rpms"
# end

# package "https://rdoproject.org/repos/openstack-mitaka/rdo-release-mitaka.rpm" do
# 	action :install
# end

remote_file "/etc/yum.repos.d/datastax.repo" do
	owner "root"
	user "root"
	mode "0644"
	source "../templates/datastax.repo"
end

remote_file "/etc/yum.repos.d/midonet.repo" do
	owner "root"
	user "root"
	mode "0644"
	source "../templates/midonet.repo"
end

include_recipe "update-yum"
