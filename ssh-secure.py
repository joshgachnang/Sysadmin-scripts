#!/usr/bin/python

config = '/etc/ssh/sshd_config'

replace_strings = {
	{'UsePrivilegeSeparation no', 'UsePrivilegeSeparation yes'},
	{'PermitRootLogin yes', 'PermitRootLogin no'},
	{'PermitEmptyPasswords yes' 'PermitEmptyPasswords no'},
	{'Port 22', 'Port 1899'},
	{"#Banner /etc/issue.net", "Banner /etc/issue.net"},
}

#Check sudo


#Backup the file
import shutil

shutil.copy(config, config + '.bak')

#Search for the strings that need to be changed
import fileinput

for lines in fileinput.FileInput(config, inplace=1): ## edit file in place
	for string_set in replace_strings:
		lines = lines.replace(string_set{0},string_set{1})
		print lines ## although this prints the line, the file will be modified.


#Modify /etc/issue.net to not display the os version. Do something else.

#Restart the server

