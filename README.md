# BackupR - automatic backuping tool
Backup many hosts without maintaining multiple lists of them. 
Simply give BackupR certain hostgroup name from your Zabbix monitoring and it will automatically backup whole hostgroup.

Hostgroup has to contain only hosts of one type.

##### Currently supported host types
* Mikrotik
* Ubiquiti
* Linux (under development)

## Usage
```
$ backupr -h
Usage: backupr [options]
    -c, --config CONFIG_PATH         Path to configuration file
    -g, --genconfig CONFIG_PATH      Generate blank config to given path
    -h, --help                       Display this screen
```
Check example config.yml. You have to specify Zabbix API url, user, password and enable at least one host group.

