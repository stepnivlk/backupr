# Handles commands to hosts through SSH and SCP.
module SecNetCommands
  require 'net/ssh'
  require 'net/scp'

  def connect_to_host(host, user, password, ssh = true)
    begin
      @ssh = Net::SSH.start(host, user, password: password) if ssh == true
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