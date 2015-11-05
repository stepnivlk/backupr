# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'backupr/version'

Gem::Specification.new do |s|
  s.name          = "backupr"
  s.version       = BackuprVersion::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Tomas Koutsky"]
  s.email         = ["tomas at stepnivlk.net"]
  s.homepage      = "http://stepnivlk.net"
  s.license       = "MIT"
  s.summary       = %q{Modular batch backuping tool}
  s.description   = %{Automatically backups groups of all hosts from given Zabbix
                      hostgroup, through Zabbix API.}
  s.files         = `git ls-files`.split($\)
  s.require_paths = ["lib"]
  s.executables   = ["backupr"]

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_dependency("zabbixapi", "~> 2.4")
end