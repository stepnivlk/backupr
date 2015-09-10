require 'date'
require './source_modules'
require './target_modules'

# Contains main logic behind whole backup process.
# All other components are called from this class.
# Creates directory structure and takes care of deleting old files.
# Backup targets and sources are objects.
class MainBackup
  def initialize(config)
    @config = config
    include ZabbixSource if @config[:zabbix][:use]
    include MikrotikTarget if @config[:mikrotik][:use]
    @zabbix = ZabbixHostsMiner.new(@config[:zabbix][:url], @config[:zabbix][:user], 
                                   @config[:zabbix][:password]) if @config[:zabbix][:use]

    base_file_name = Date.today.strftime(@config[:date_format])
    @working_directory = @config[:backup_directory]
  end

  def start(delete_old = true)
    zabbix_get_backup_ips if @zabbix
    check_or_create_working_dir
    check_or_create_group_dirs
    check_or_create_group_ips_dirs

    if @config[:groups][:mikrotik][:use] && @config[:groups][:mikrotik][:ips] != nil
      mikrotik = MikrotikBackup.new(@config[:groups][:mikrotik][:ips], 
                                    @config[:groups][:mikrotik][:user], 
                                    @config[:groups][:mikrotik][:password], 
                                    @working_directory + @config[:groups][:mikrotik][:name] + "/",
                                    base_file_name)
      mikrotik.backup_hosts(@config[:groups][:mikrotik][:backup_format])
      if @config[:groups][:mikrotik][:delete_old]
        delete_older_than(@config[:groups][:mikrotik][:name], 
                          @config[:groups][:mikrotik][:delete_older_than])
      end
    end
  end

 # private
      # gets array of IPs from zabbix and adds them to config hash.
      def zabbix_get_backup_ips
        @config[:groups].each do |key, value|
          if value[:use]
            ips = @zabbix.get_ips_by_group(value[:name])
            @config[:groups][key.to_sym][:ips] = ips
          end
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

      # Creates backup directory if superior directory is writable.
      # Returns true after creating directory, or after writability check.
      def check_or_create_working_dir
        unless Dir.exists?(@working_directory)
          if File.writable?(@working_directory.split("/")[0...-1].join("/"))
            Dir.mkdir(@working_directory)
            return true if Dir.exists?(@working_directory)
          end
        end
        return false unless File.writable?(@working_directory) 
      end

      # Create directories of groups from config.
      # Returns all directories in backup directory.
      def check_or_create_group_dirs
        change_dir(@working_directory)
        @config[:groups].each do |key, value|
          if value[:use]
            Dir.mkdir(value[:name].downcase) unless Dir.exists?(value[:name].downcase)  
          end          
        end
        return Dir.glob('*').select { |f| File.directory? f }
      end

      # Create all subdirectories named by host IPs.
      def check_or_create_group_ips_dirs
        @config[:groups].each do |key, value|
          if value[:use]
            change_dir(@working_directory+value[:name])
            begin
              unless value[:ips] == nil
                value[:ips].each do |ip|
                  Dir.mkdir(ip.gsub(/[.]/, '-')) unless Dir.exists?(ip.gsub(/[.]/, '-'))
                end
              end
            rescue Exception => error
              change_dir(@working_directory)
              puts error.message
            end
          end
        end
        change_dir(@working_directory)
      end

      # Deletes all files in subfolders of given folder(group). 
      # Checks if that filename is older than days variable with is_outdated? method. 
      # Deletes only files matching pattern. 
      # Works by printing directory structure into arrays.
      def delete_older_than(group, days = 14)
        past = (DATE-days).strftime("%d-%m-%Y")

        change_dir(@working_directory + group.to_s)
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
            change_dir(@working_directory + group.to_s)
          end
        end

      end

      # checks if date in given filename is older past_days ago.
      def is_outdated?(past_days, file)
        past = DATE - past_days
        return true if (Date.parse(file) < past)
      end

end