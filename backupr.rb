require './main_backup' 
require 'yaml'

DATE = Date.today
BASE_FILE_NAME = DATE.strftime("%d-%m-%Y")
WORKING_DIRECTORY = "/"

c = { mikrotik: {name: "mikrotik", user: "xx", password: "yy", 
                      backup_format: :both, filenames: BASE_FILE_NAME}, 
           ubiquiti: {name: "ubiquiti", user: "xx", password: "yy"},
           linux: {name: "linux", user: "xx", password: "yy"} }


zabbix_config = { url: "http://zabbix.ernet/api_jsonrpc.php",
                  user: "Admin", password: "zabbix" }

config = YAML.load_file('config.yml')