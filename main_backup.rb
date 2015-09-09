require 'date'
require './zabbix_hosts_miner'
require './mikrotik_backup'

class MainBackup
  def initialize(config, zabbix_config, dir)
    @config = config
    @zabbix = ZabbixHostsMiner.new(zabbix_config[:url], 
                           zabbix_config[:user], zabbix_config[:password])    
  end

  def start(delete_old = true)
    get_backup_ips
    check_or_create_group_dirs
    check_or_create_group_ips_dirs

    if @config.include?(:mikrotik) && @config[:mikrotik][:ips] != nil
      mikrotik = MikrotikBackup.new(@config[:mikrotik][:ips], @config[:mikrotik][:user], 
                    @config[:mikrotik][:password], 
                    WORKING_DIRECTORY + @config[:mikrotik][:name] + "/", BASE_FILE_NAME)
      mikrotik.backup_hosts(@config[:mikrotik][:backup_format])
      delete_older_than(@config[:mikrotik][:name]) if delete_old
    end
  end

  def to_s
    puts @config
  end



  private
      # gets array of IPs from zabbix and adds them to config hash.
      def get_backup_ips
        @config.each do |key, value|
          ips = @zabbix.get_ips_by_group(value[:name])
          @config[key.to_sym][:ips] = ips
        end
        return @config
      end



      # Change directory or rescue if not.
      def change_dir(dir)
        begin
          return true if Dir.chdir(dir)
        rescue Exception => error
          puts error.message
        end
      end

      # Create directories of groups from config.
      # Returns all directories in backup directory.
      def check_or_create_group_dirs
        change_dir(WORKING_DIRECTORY)
        @config.each do |key, value|
          if Dir.exists?(value[:name].downcase) == false
            Dir.mkdir(value[:name].downcase)
          end
        end
        return Dir.glob('*').select { |f| File.directory? f }
      end

      # Create all subdirectories named by host IPs.
      def check_or_create_group_ips_dirs
        @config.each do |key, value|
          change_dir(WORKING_DIRECTORY+value[:name])
          begin
            unless value[:ips] == nil
              value[:ips].each do |ip|
                Dir.mkdir(ip.gsub(/[.]/, '-')) if Dir.exists?(ip.gsub(/[.]/, '-')) == false
              end
            end
          rescue Exception => error
            change_dir(WORKING_DIRECTORY)
            puts error.message
          end
        end
        change_dir(WORKING_DIRECTORY)
      end

      # Deletes all files in subfolders of given folder(group). 
      # Checks if that filename is older than days variable with is_outdated? method. 
      # Deletes only files matching pattern. 
      # Works by printing directory structure into arrays.
      def delete_older_than(group, days = 14)
        past = (DATE-14).strftime("%d-%m-%Y")

        change_dir(WORKING_DIRECTORY + group.to_s)
        dirs = Dir.glob('*').select { |f| File.directory?(f) }
        dirs.each do |dir|
          if change_dir(dir)
            files = Dir.glob('*').select { |f| f =~ /^\d{2}\-\d{2}\-\d{4}\.\w{3,6}/ }

            unless files.size == 0
              files.each do |f| 
                if is_outdated?(days, f)
                  puts "#{Dir.pwd}: Outdated file #{f} deleted!" if File.delete(f)
                end
              end
            end
            change_dir(WORKING_DIRECTORY + group.to_s)
          end
        end

      end

      # checks if date in given filename is older past_days ago.
      def is_outdated?(past_days, file)
        past = DATE - past_days
        return true if (Date.parse(file) < past)
      end

end