#!/usr/bin/env ruby

require './main_backup' 
require 'yaml'
require 'optparse'
require 'date'

# BackupR by StepniVlk
# version: 0.2.5

options = {config_path: "/default/path"}
option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: backupr.rb [options]"
  opts.on("-c", "--config CONFIG_PATH", "Path to configuration file") do |config_path|
    unless File.exists?(config_path)
      warn "Config file does not exist!"
      exit 1
    end
    options[:config_path] = config_path if config_path.size > 0
  end
end
option_parser.parse!
puts options.inspect



begin
  if config = YAML.load_file(options[:config_path])
   config[:backup_directory].insert(-1, "/") unless config[:backup_directory][-1] == "/"
   puts "Config file loaded and checked!"
  end 
rescue Exception => error
  puts error.message
end


backupr = MainBackup.new(config)
backupr.start