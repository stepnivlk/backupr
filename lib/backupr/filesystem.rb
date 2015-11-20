module Backupr
  class Filesystem
    def build_directories(groupname, ips)

    end

    # Creates backup directory if superior directory is writable.
    # Returns true after creating directory, or after writability check.
    def create_directory(directory)
      return true if Dir.exist?(directory)
      
      begin
        return true if writable_superior?(directory) && Dir.mkdir(directory) 
      rescue Exception => error
        Loggers::Main.log.warn error.message 
        exit 8
      end
    end

    def writable_superior?(directory)
      File.writable?(directory.split("/")[0...-1].join("/"))
    end


    def change_directory(directory)
      begin
        return true if Dir.chdir(directory)
      rescue Exception => error
        Loggers::Main.log.warn error.message
        exit 5
      end
    end

    # Deletes all files in subfolders of given folder(group). 
    # Checks if that filename is older than days variable with is_outdated? method. 
    # Deletes only files matching pattern. 
    # Works by printing directory structure into arrays.
    def delete_outdated!(days = 14)
      files = Dir.glob('*').select { |f| f =~ /^\d{2}\-\d{2}\-\d{4}\.\w{3,6}/ }

      unless files.size == 0
        files.each do |f| 
          if is_outdated?(days, f)
            Loggers::Main.log.info "#{Dir.pwd}: Outdated file #{f} deleted!" if File.delete(f)
          end
        end
      end
    end

    # checks if date in given filename is older past_days ago.
    def is_outdated?(days, file)
      past = Date.today - days
      return true if (Date.parse(file) < past)
    end
  end
end