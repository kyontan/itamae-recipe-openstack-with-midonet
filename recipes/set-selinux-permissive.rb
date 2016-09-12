execute "set selinux permissive" do
	command "setenforce permissive"
	not_if "getenforce | grep -i permissive"
end

file "/etc/sysconfig/selinux" do
	action :edit

	block do |content|
		content.gsub!("SELINUX=enforcing", "SELINUX=permissive")
	end
end

file "/etc/selinux/config" do
	action :edit

	block do |content|
		content.gsub!("SELINUX=enforcing", "SELINUX=permissive")
	end
end
