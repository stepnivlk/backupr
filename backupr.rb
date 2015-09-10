require './main_backup' 
require 'yaml'

# BackupR by StepniVlk
# version: 0.2.1

begin
  if config = YAML.load_file('config.yml')
   config[:backup_directory].insert(-1, "/") unless config[:backup_directory][-1] == "/"
   puts "Config file loaded and checked!"
  end 
rescue Exception => error
  puts error.message
end


backupr = MainBackup.new(config)
backupr.start