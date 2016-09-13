service "firewalld.service" do
	action [:stop, :disable]
end
