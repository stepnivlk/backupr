module SecNetCommands
	require 'net/ssh'
	require 'net/scp'

	def connect_to_host(host, user, password)
		begin
			@ssh = Net::SSH.start(host, user, password: password)
			@host = host
			@user = user
			@password = password
			return true
		rescue Exception => error
			exit
		end
	end

	def send_command(command)
		@ssh.exec!(command)
	end

	def download_file(local_path, remote_path)
		Net::SCP.download!(@host, @user, remote_path, local_path, 
												ssh: { password: @password })
	end

	def close
		begin
			@ssh.close
			return true
		rescue Exception => error
			return "already disconnected"
		end
	end
end