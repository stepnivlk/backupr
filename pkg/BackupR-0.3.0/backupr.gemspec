# -*- encoding: utf-8 -*-
require File.expand_path('../lib/backupr/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = "BackupR"
  s.version       = Backupr::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Tomas Koutsky"]
  s.email         = ["tomas at stepnivlk.net"]
  s.homepage      = "http://stepnivlk.net"
  s.summary       = %q{Modular batch backuping tool}
  s.description   = %{Automatically backups groups of all hosts from given Zabbix
                      hostgroup, through Zabbix API.}
  s.files         = `git ls-files`.split($\)
  s.require_paths = ["lib"]
  s.executables   = ["backupr"]
  s.add_dependency("zabbixapi")
end