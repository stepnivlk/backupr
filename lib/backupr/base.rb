

module Backupr
# Contains main logic behind whole backup process.
# All other components are called from this class.
# Creates directory structure and takes care of deleting old files.
# Backup targets and sources are objects.
class Base
  include ConfigChecker

  def initialize(options)
    @date = Date.today
    @config = load_config(options)
    @working_directory = @config[:backup_directory]
    @zabbix = ZabbixHostsMiner.new(@config[:zabbix][:url],
                                   @config[:zabbix][:user], 
                                   @config[:zabbix][:password]) if @config[:zabbix][:enable]
    zabbix_get_backup_ips
  end

  def mikrotik
    config = @config[:groups][:mikrotik]
    config[:ips] = @zabbix.get_ips_by_group(config[:name])
    mikrotik = MikrotikBackup.new(config)
    mikrotik.backup_hosts
  end

  def ubiquiti
    config = @config[:groups][:ubiquiti]
    config[:ips] = @zabbix.get_ips_by_group(config[:name])
    ubiquiti= UbiquitiBackup.new(config)
    ubiquiti.backup_hosts
  end

  private

  def group_enabled?(group)
    return true if @config[:groups][group.to_sym][:enable] && !@config[:groups][group.to_sym][:ips].nil?
  end

  # gets array of IPs from zabbix and adds them to config hash.
  def zabbix_get_backup_ips
    @config[:groups].each do |group, parameter|
      if parameter[:enable]
        ips = @zabbix.get_ips_by_group(parameter[:name])
        @config[:groups][group.to_sym][:ips] = ips
      end
    end
    @config
  end

  # Creates backup directory if superior directory is writable.
  # Returns true after creating directory, or after writability check.
  def check_or_create_working_dir
    unless Dir.exist?(@working_directory)
      if File.writable?(@working_directory.split("/")[0...-1].join("/"))
        Dir.mkdir(@working_directory)
        return true if Dir.exist?(@working_directory)
      end
    end
    Loggers::Main.log.warn "Creation of #{@working_directory} failed!" unless Dir.exist?(@working_directory)
  end

  # Create directories of groups from config.
  # Returns true.
  def check_or_create_group_dirs
    change_dir(@working_directory)
    @config[:groups].each do |key, value|
      if value[:enable]
        Dir.mkdir(value[:name].downcase) unless Dir.exists?(value[:name].downcase)  
      end          
    end
    return true
  end

  # Create all subdirectories named by host IPs.
  def check_or_create_group_ips_dirs
    @config[:groups].each do |key, value|
      if value[:enable]
        change_dir(@working_directory+value[:name])
        begin
          unless value[:ips] == nil
            value[:ips].each do |ip|
              Dir.mkdir(ip.gsub(/[.]/, '-')) unless Dir.exists?(ip.gsub(/[.]/, '-'))
            end
          end
        rescue Exception => error
          change_dir(@working_directory)
          Loggers::Main.log.warn error.message
          exit 6
        end
      end
    end
    change_dir(@working_directory)
  end


  # Change directory or rescue if not.
  def change_dir(dir)
  #  begin
      return true if Dir.chdir(dir)
    #rescue Exception => error
   #   Loggers::Main.log.warn error.message
  #    exit 5
  #  end
  end

end
end
