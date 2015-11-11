require 'rubygems/package_task'
require "rspec/core/rake_task"

spec = eval(File.read('backupr.gemspec'))
Gem::PackageTask.new(spec) do |pkg|
end

RSpec::Core::RakeTask.new(:spec)

task :default => :tasklist

desc 'Show Rake Tasks (`rake -T`)'
task :tasklist do
  exec 'rake -T'
end

desc 'Open a pry console in the Backup context'
task :console do
  require 'pry'
  require 'backupr'
  ARGV.clear
  Pry.start || exit
end