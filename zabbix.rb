require "zabbixapi"

class ZabbixGet

	def initialize(zabbix_api_url, zabbix_user, zabbix_password)
		@url = zabbix_api_url
		@user = zabbix_user
		@password =zabbix_password
		connect
		get_all_groups
	end

	# vrati pole s hashem zavolane skupiny
	def get_group_by_name(name)
		@groups.each do |group|
			if group[0]["name"].downcase == name.downcase
				return group
			end
		end
	end

	# vrati pole s hashema jednotlivych hostu
	def get_hosts_by_group(name)
		begin
			groupid = get_group_by_name(name)[0]["groupid"].to_i
			hosts = @zbx.query( method: "host.get", params: {"output" => "extend", "groupids" => [groupid] } )
		rescue Exception => error
			return nil
		end
	end

	# vrati pole s id hostu v dane skupine
	def get_hostids_by_group(name)
		hostids = []
		hosts = get_hosts_by_group(name)
		if hosts == nil
			return nil
		else
			hosts.each { |host| hostids.push(host["hostid"].to_i) }
			return hostids
		end
	end

	# vrati ip hostu z dane skupiny
	def get_ips_by_group(name)
		hostids = get_hostids_by_group(name)
		hostips = []
		if hostids == nil 
			return nil
		else
			hostids.each do |hostid|
				hostips.push(@zbx.query( method: "hostinterface.get", params: {"output" => "extend", "hostids" => [hostid] } )[0]["ip"])
			end
	 		return hostips
	 	end
	end

	def print_groups
		@groups
	end

	def print_zbx
		@zbx
	end


	private

	def connect
		begin
			@zbx = ZabbixApi.connect(url: @url, 
															user: @user, password: @password)
		rescue Exception => error
			puts "no connection"
			exit
		end
	end

	# vrati pole vsech hostgroups na zbx host
	def get_all_groups(empty_size = 2)
		@groups = []
		iter = 1
		empty_buffer = 0

		loop do
			group = @zbx.query( method: "hostgroup.get", params: {"output" => "extend", "groupids" => [iter] } )
			iter += 1

			if group != []
				@groups.push(group)
			else
				empty_buffer += 1
			end

			# empty_size - pocet nasledujicich prazdnych poli, pri kterem dojde k preruseni
			if empty_buffer > empty_size
				break
			end
		end
		return true if @groups.size > 0
	end

end