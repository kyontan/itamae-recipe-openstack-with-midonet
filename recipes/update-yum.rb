execute "clean yum repository cache" do
	user "root"
	command "yum clean all"
end

execute "update yum repo" do
	user "root"
	command "yum -y update"
end
