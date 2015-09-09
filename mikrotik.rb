require './secure_net'

class MikrotikBackup
	
	include SecureNet

	def initialize(hostips, user, password, path_prefix, filenames)
		@hostips = hostips
		@user = user
		@password = password
		@path_prefix = path_prefix
		@name = filenames

	end

	def backup_hosts(format = :both, download = true, del_after_down = true)
		@hostips.each do |hostip|
			local_path = @path_prefix + hostip.gsub(/[.]/, '-') + "/"

			puts "#{hostip}: connected" if connect_to_host(hostip, @user, @password)

			case format
			when :binary
				mk_backup(hostip, :binary)
				if download == true && download_file(local_path, @name + ".backup")
					puts "#{hostip}: #{@name}.backup downloaded"
					mk_delete(hostip, @name + ".backup") if del_after_down == true
				end
			when :export
				mk_backup(hostip, :export)
				if download == true && download_file(local_path, @name + ".rsc")
					puts "#{hostip}: #{@name}.rsc downloaded" 
				end
			when :both
				mk_backup(hostip, :binary)
				mk_backup(hostip, :export)
				if download == true
					puts "#{hostip}: #{@name}.backup downloaded" if download_file(local_path, @name + ".backup")
					puts "#{hostip}: #{@name}.rsc downloaded" if download_file(local_path, @name + ".rsc")
				end
			end

			puts "#{hostip}: closed" if close

		end
	end

	private


			def mk_backup(hostip, format)
				if format == :binary
					puts "#{hostip}: #{@name}.backup saved" if send_command("/system backup save name=#{@name}")
				elsif format == :export
					send_command("/export file=#{@name}")
					puts "#{hostip}: #{@name}.rsc saved"
				end
			end

			def mk_delete(hostip, file)
				send_command("/file remove \"#{file}\"")
				puts "#{hostip}: #{file} deleted from host"
			end

end