require_relative 'helpers'
require_relative 'file'
require_relative 'helpers'
require 'rsync'
require 'date'

module Backupr
  class MikrotikBackup < Filesystem
    include SecNetCommands

    def initialize(config)
      @hostips = config[:ips]
      @user = config[:user]
      @password = config[:password]
      # path to group directory
      @working_directory = config[:working_directory]
      @name = Date.today.strftime(config[:date_format])
    end

    def backup_hosts(format = :both, download = true, del_after_down = true)
      create_directory(@working_directory)
      @hostips.each do |hostip|
        Dir.chdir(@working_directory + hostip) if create_directory(@working_directory + hostip)
        # whole path to each host directory (IP)
        local_path = Dir.pwd

        Loggers::Main.log.info "[M] #{hostip}: connected" if connect_to_host(hostip, @user, @password)

        case format
        when :binary
          mk_backup(hostip, :binary)
          if download == true && download_file(local_path, @name + ".backup")
            Loggers::Main.log.info "[M] #{hostip}: #{@name}.backup downloaded"
            mk_delete(hostip, @name + ".backup") if del_after_down == true
          end
        when :export
          mk_backup(hostip, :export)
          if download == true && download_file(local_path, @name + ".rsc")
            Loggers::Main.log.info "[M]: #{hostip}: #{@name}.rsc downloaded" 
          end
        when :both
          mk_backup(hostip, :binary)
          mk_backup(hostip, :export)
          if download == true
            Loggers::Main.log.info "[M] #{hostip}: #{@name}.backup downloaded" if download_file(local_path, @name + ".backup")
            Loggers::Main.log.info "[M] #{hostip}: #{@name}.rsc downloaded" if download_file(local_path, @name + ".rsc")
          end
        end

        Loggers::Main.log.info "[M] #{hostip}: closed" if close
      end
    end

    private

    def mk_backup(hostip, format)
      if format == :binary
        Loggers::Main.log.info "[M] #{hostip}: #{@name}.backup saved" if send_command("/system backup save name=#{@name}")
      elsif format == :export
        send_command("/export file=#{@name}")
        Loggers::Main.log.info "[M] #{hostip}: #{@name}.rsc saved"
      end
    end

    def mk_delete(hostip, file)
      send_command("/file remove \"#{file}\"")
      Loggers::Main.log.info "#[M] {hostip}: #{file} deleted from host"
    end
  end

  class UbiquitiBackup < File
    include SecNetCommands

    def initialize(hostips, user, password, path_prefix, filenames)
      @hostips = hostips
      @user = user
      @password = password
      # path to group directory
      @path_prefix = path_prefix
      @name = filenames

    end

    def backup_hosts
      @hostips.each do |hostip|
        # whole path to each host directory (IP)
        local_path = @path_prefix + hostip.gsub(/[.]/, '-') + "/"
        connect_to_host(hostip, @user, @password, ssh = false)
        Loggers::Main.log.info "[U] #{hostip}: #{@name}.cfg downloaded" if download_file(local_path + @name + ".cfg" , "/tmp/system.cfg")
      end
    end
  end

  class LinuxBackup < File

    def initialize(hostips, password, path_prefix, filenames, args)
      @hostips = hostips
      @password = password
      @path_prefix = path_prefix
      @name = filenames
      @args = args
      @hosts_with_modules = {}
    end

    def set_env_password(password)
      ENV['RSYNC_PASSWORD'] = password
    end

    def get_backup_modules(hostips)
      hostips.each do |hostip|
        @hosts_with_modules[hostip] = Rsync.run("rsync://#{hostip}", "").list_modules.keys
      end
    end

    def backup_hosts
      @hosts_with_modules.each do |hostip, modules|
        local_path = @path_prefix + hostip.gsub(/[.]/, '-') + "/"
        change_dir(local_path)
        modules.each do |modul|
          Dir.mkdir(modul) unless Dir.exists?(modul)
          Rsync.run("#{hostip}::#{modul}", local_path, @args)
        end
      end
    end

  end

end