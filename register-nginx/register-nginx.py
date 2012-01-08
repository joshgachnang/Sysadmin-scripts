#/usr/bin/env python

# This script sits on an Nginx server, and is run by remote Apache/Nginx
# or app servers to register themselves in a cluster with Nginx. We are using
# this on EC2, to let web/php servers register with the Nginx load balancer.

# Assumes nginx.conf has an upstream default in the config like so:
# upstream default { include /etc/nginx/default.upstream; }
# This file is simply a list of hostnames.
# You may include other upstream files, in the form:
# upstream cluster_name { include /etc/nginx/cluster_name.upstream; }

# Usage: python register-nginx.py [-d/--deregister] client_hostname [cluster_name]

# By the way, I know this is UGLY. But it was quick and dirty. Some day, I might
# fix it.

import sys

DEBUG = False

if DEBUG:
	file_template = "%s.upstream"	
else:
	file_template = "/etc/nginx/%s.upstream"

def register(hostname, cluster="default"):
	# See if the hostname exists already
	with open(file_template % cluster) as cluster_file:
		for line in cluster_file.readlines():
			if hostname + '\n' == line:
				print "Host %s already registered with cluster %s" % (hostname, cluster)
				sys.exit(1)
	# Append the new hostname to the file
	with open(file_template % cluster, 'a') as cluster_file:
		cluster_file.write(hostname + '\n')
def deregister(hostname, cluster="default"):
	new_file = []
	# Read through the file, add all lines that aren't the hostname to a new array 	
	with open(file_template % cluster, 'r') as cluster_file:
		lines = cluster_file.readlines()
		old_file_len = len(lines)
		for line in lines:
			print hostname, line
			if hostname + '\n' != line:
				new_file.append(line)
	if len(new_file) == old_file_len:
		print "Host %s not registered with cluster %s" % (hostname, cluster)
		sys.exit(2)
	# Write the array, minus the deregistered hostname, to the file
	with open(file_template % cluster, 'w') as cluster_file:
		for line in new_file:
			cluster_file.write(line)

if __name__ == "__main__":
	# arv[0] == appname, argv[1] == first arg, etc If len == 2: default register, 3: deregister OR other cluster. 4: deregister other cluster
	if len(sys.argv) == 2:
		register(sys.argv[1])
	elif len(sys.argv) == 3:
		if sys.argv[1] == '-d' or sys.argv[1] == '--deregister':
			deregister(sys.argv[2])
		else:
			register(sys.argv[1], sys.argv[2])
	elif len(sys.argv) == 4:
		deregister(sys.argv[2], sys.argv[3])
	else:
		print "usage:"
		print "python register-nginx.py [-d/--deregister] hostname [cluster_name]"
