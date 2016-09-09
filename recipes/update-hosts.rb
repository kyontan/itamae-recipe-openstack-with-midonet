file "/etc/hosts" do
	action :edit

	block do |content|
		node[:hosts].each do |host|
			if not /#{host[:ip]}\s+#{host[:name]}/ === content
				content << "#{host[:ip]}\t#{host[:name]}\n"
			end
		end
	end
end
