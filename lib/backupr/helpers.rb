
# Handles commands to hosts through SSH and SCP.
module SecNetCommands


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
      Loggers::Main.log.warn error.message
      return false
    end
  end
end

module Loggers
  

  class Main
    def self.log
      if @logger.nil?
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
      end
    @logger
    end
  end
end

module ConfigChecker

  def load_config(options)
    config_exists?(options)
    if config = YAML.load_file(options[:config_path])
      check_config(config)
      Loggers::Main.log.info "Config file loaded and checked!"
      return config
    else
      Loggers::Main.log.fatal "Wrong/corrupted config file!"
      exit 2
    end
  end

  def config_exists?(options)
    unless File.exists?(options[:config_path])
      Loggers::Main.log.fatal "Non existent config file given!"
      exit 1
    end
    return true
  end

  def check_config(config)
    # Appends "/" to end of backup_directory, if there is none.
    config[:backup_directory].insert(-1, "/") unless config[:backup_directory][-1] == "/"

    # Checks if at least one group is enabled.
    group_enable = {}
    config[:groups].each { |group, value| group_enable[group] = value[:enable] }
    unless group_enable.has_value?(true)
       Loggers::Main.log.warn "No group enabled, enable any in config file. Exiting..."
       exit 3
    end

    # Checks if delete_older_than_days is not negative
    config[:groups].each do |group, value|  
      if value[:delete_older_than_days] && value[:delete_older_than_days] < 0
        Loggers::Main.log.warn "Negative delete_older_than_days value, please make it positive."
        exit 4
      end
    end
    return true
  end
  
end