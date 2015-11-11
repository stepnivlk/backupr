module Backupr
  class Filesystem
    def build_directories(groupname, ips)

    end

    # Creates backup directory if superior directory is writable.
    # Returns true after creating directory, or after writability check.
    def create_directory(directory)
      unless Dir.exist?(directory)
        Dir.mkdir(directory) if writable_superior?(directory)
      end

      # else
      #   Loggers::Main.log.warn "Creation of #{directory} failed!" 
      #   exit 8
      # end
    end

    def writable_superior?(directory)
      File.writable?(directory.split("/")[0...-1].join("/"))
    end


    def change_directory(directory)
      #  begin
      return true if Dir.chdir(directory)
      #rescue Exception => error
      #   Loggers::Main.log.warn error.message
      #    exit 5
      #  end
    end

  end
end