require_relative 'helpers'
require_relative 'filesystem'
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
      @working_directory = config[:working_directory]
      @name = Date.today.strftime(config[:date_format])
    end

    def backup_hosts(format = :both, download = true, del_after_down = true)
      create_directory(@working_directory)

      @hostips.each do |hostip|
        host_directory = @working_directory + hostip

        change_directory(host_directory) if create_directory(host_directory)
        delete_outdated!

        Loggers::Main.log.info "[M] #{hostip}: connected" if connect_to_host(hostip, @user, @password)

        case format
        when :binary
          mk_backup(hostip, :binary)
          if download == true && download_file(host_directory, @name + ".backup")
            Loggers::Main.log.info "[M] #{hostip}: #{@name}.backup downloaded"
            mk_delete(hostip, @name + ".backup") if del_after_down == true
          end
        when :export
          mk_backup(hostip, :export)
          if download == true && download_file(host_directory, @name + ".rsc")
            Loggers::Main.log.info "[M]: #{hostip}: #{@name}.rsc downloaded" 
          end
        when :both
          mk_backup(hostip, :binary)
          mk_backup(hostip, :export)
          if download == true
            Loggers::Main.log.info "[M] #{hostip}: #{@name}.backup downloaded" if download_file(host_directory, @name + ".backup")
            Loggers::Main.log.info "[M] #{hostip}: #{@name}.rsc downloaded" if download_file(host_directory, @name + ".rsc")
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

    def initialize(config)
      @hostips = config[:ips]
      @user = config[:user]
      @password = config[:password]
      @working_directory = config[:working_directory]
      @name = Date.today.strftime(config[:date_format])
    end

    def backup_hosts
      create_directory(@working_directory)

      @hostips.each do |hostip|
        host_directory = @working_directory + hostip

        change_directory(host_directory) if create_directory(host_directory)
        delete_outdated!

        connect_to_host(hostip, @user, @password, ssh = false)
        if download_file(host_directory + @name + ".cfg" , "/tmp/system.cfg")
          Loggers::Main.log.info "[U] #{hostip}: #{@name}.cfg downloaded"
        end
      end
    end
  end

  class LinuxBackup < Filesystem

    def initialize(config)
      @hostips = config[:ips]
      @password = config[:password]
      @working_directory = config[:working_directory]
      @name = Date.today.strftime(config[:date_format])
      @args = config[:args]
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

    def to_s
      @hosts_with_modules
    end

    def backup_hosts
      create_directory(@working_directory)

      @hosts_with_modules.each do |hostip, modules|
        @host_directory = @working_directory + hostip + "/"
        create_directory(@host_directory)

        modules.each do |modul|
          modul_directory = @host_directory + modul
          change_directory(modul_directory) if create_directory(modul_directory)

          Rsync.run("#{hostip}::#{modul}", modul_directory, @args)
        end
      end
    end

  end

end