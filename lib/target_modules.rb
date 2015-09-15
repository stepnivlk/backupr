require 'helper_modules'

module MikrotikTarget 
  class MikrotikBackup
    
    include SecNetCommands

    def initialize(hostips, user, password, path_prefix, filenames)
      @hostips = hostips
      @user = user
      @password = password
      # path to group directory
      @path_prefix = path_prefix
      @name = filenames

    end

    def backup_hosts(format = :both, download = true, del_after_down = true)
      @hostips.each do |hostip|
        # whole path to each host directory (IP)
        local_path = @path_prefix + hostip.gsub(/[.]/, '-') + "/"

        puts "[M] #{hostip}: connected" if connect_to_host(hostip, @user, @password)

        case format
        when :binary
          mk_backup(hostip, :binary)
          if download == true && download_file(local_path, @name + ".backup")
            puts "[M] #{hostip}: #{@name}.backup downloaded"
            mk_delete(hostip, @name + ".backup") if del_after_down == true
          end
        when :export
          mk_backup(hostip, :export)
          if download == true && download_file(local_path, @name + ".rsc")
            puts "[M]: #{hostip}: #{@name}.rsc downloaded" 
          end
        when :both
          mk_backup(hostip, :binary)
          mk_backup(hostip, :export)
          if download == true
            puts "[M] #{hostip}: #{@name}.backup downloaded" if download_file(local_path, @name + ".backup")
            puts "[M] #{hostip}: #{@name}.rsc downloaded" if download_file(local_path, @name + ".rsc")
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
end

module UbiquitiTarget
  class UbiquitiBackup
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
        puts "[U] #{hostip}: #{@name}.cfg downloaded" if download_file(local_path + @name + ".cfg" , "/tmp/system.cfg")

      end
    end
  end
end