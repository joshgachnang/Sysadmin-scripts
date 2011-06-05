#!/usr/bin/python
# Copyright Josh Gachnang 2010
# Release under the New BSD License
# ServerCobra.com

# Based off http://www.straw-dogs.co.uk/12/10/python-virtual-host-creator/

#Builds /etc/apache/sites-available/file
#Add user
#Build www dir /home/user/domain.com
#a2ensite sitename

import getopt
import os
import subprocess
import sys
from random import randint, choice
import string

def main(argv):

  try:
    opts, args = getopt.getopt(argv, "hd:a:", ["help", "domain="])
  except getopt.GetoptError:
    usage()
    sys.exit(2)

  if len(opts) == 0:
    usage()
    sys.exit(2)

  for o, a in opts:
    if o in ("-h", "--help"):
      usage()
      sys.exit()
    if o in ("-d", "--domain"):
      domain = a
      normalize_domain = domain.replace(".", "__")
    else:
      assert False, "unhandled option"


  #if not os.path.isdir("/var/www/%s" % directory):
   # os.mkdir("/var/www/%s" % directory)

  #if not os.path.isdir("/var/www/%s/htdocs" % directory):
   # os.mkdir("/var/www/%s/htdocs" % directory)

  default_vhost_template = """
  <VirtualHost *:80>
    ServerName __DOMAIN__
    ServerAlias www.__DOMAIN__
    
    
    #Log files
    CustomLog /home/__NORM_DOM__/__NORM_DOM__/logs/access.log combined
    ErrorLog /home/__NORM_DOM__/__NORM_DOM__/logs/error.log

    ErrorDocument 404 /404.html
    ErrorDocument 401 /401.html
    ErrorDocument 500 /500.html

    DocumentRoot /home/__NORM_DOM__/__NORM_DOM__/htdocs
    <Directory /home/__NORM_DOM__/__NORM_DOM__/htdocs >
      Options +Indexes +FollowSymlinks +ExecCGI +Includes -MultiViews
      AllowOverride All
      Order Allow,Deny
      Allow from all
    </directory>

  </virtualhost>
  """
  
  django_vhost_template = """
  <VirtualHost *:80>
    ServerName __DOMAIN__
    ServerAlias www.__DOMAIN__
    
    
    #Log files
    CustomLog /home/__NORM_DOM__/__NORM_DOM__/logs/access.log combined
    ErrorLog /home/__NORM_DOM__/__NORM_DOM__/logs/error.log

    ErrorDocument 404 /404.html
    ErrorDocument 401 /401.html
    ErrorDocument 500 /500.html

    DocumentRoot /home/__NORM_DOM__/__NORM_DOM__/htdocs
    <Directory /home/__NORM_DOM__/__NORM_DOM__/htdocs >
      Options +Indexes +FollowSymlinks +ExecCGI +Includes -MultiViews
      AllowOverride All
      Order Allow,Deny
      Allow from all
    </directory>
    
    Alias /static /home/__NORM_DOM__/__NORM_DOM__/__APP__/static/
    <Location "/static">
	    Order allow,deny
	    Allow from all
    </Location>

    Alias /media/ /usr/lib/python-django/django/contrib/admin/media/
    <Location "/media/">
	    SetHandler None
	    Order allow,deny
	    Allow from all
    </Location>

    #Start mod_wsgi
    WSGIScriptAlias / /home/__NORM_DOM__/__NORM_DOM__/__APP__/apache/wsgi_handler.py
    <Directory "/home/__NORM_DOM__/__NORM_DOM__/__APP__/apache">
	    Order allow,deny
	    Allow from all
    </Directory>

    WSGIDaemonProcess __NORM_DOM__ user=__NORM_DOM__ group=__NORM_DOM__ processes=2 threads=10
    WSGIProcessGroup __NORM_DOM__
        
  </virtualhost>
  """
  
  
  vhost = vhost_template.replace('__DOMAIN__', domain).replace('__NORM_DOM__', normalize_domain)
  
  open('/etc/apache2/sites-available/%s.conf' % directory, 'w').write(vhost)
  os.system('a2ensite %s.conf' % directory)
  os.system('/etc/init.d/apache2 reload')

# Characters to be used while generating password
chars = string.ascii_letters + string.digits + "!#$&"

def random_password(length):
    return "".join(choice(chars) for x in range(randint(length, length)))
    
def usage():
  print 'usage: newv.py [-d domain.com]'
  print '       Please exclude the "www" at the front of the domain'
  
def run(arg):
    """
    Runs the given arg at the command line using the default shell. Outputs
    when commands are run successfully.

    Based on http://developer.spikesource.com/wiki/index.php/How_to_invoke_subprocesses_from_Python

    @param Tuple args
      A tuple of args, with the first being the command to be run, and
      the remaining ones flags and arguments for the command. STDOUT and
      STDERR are piped to tuple, waiting until the output is finished,
      then writing both to the log files, if not empty.
      Ex. ['apt-get', '-y', 'install', 'dnsmasq'], which installs
      dnsmasq using apt-get, and assumes yes to questions.
    """

    # Open output and write some info about the command to be written, including
    # name of command and arguments.
    # This could be modified to adjust how much is printed via a DEBUG variable.
    with open(os.path.join(os.curdir, "output.log"), 'a') as outFile:
	outFile.write("Command: ")
	for a in arg:
	  outFile.write(a,)
	  outFile.write(" ")
	outFile.write("\n")
    # Open output and error log file and append to them the output of the commands
    with open(os.path.join(os.curdir, "output.log"), 'a') as outFile:
	with open(os.path.join(os.curdir, "error.log"), 'a') as errorFile:
	    # Call the subprocess using convenience method

	    retval = subprocess.call(arg, -1, None, None, outFile, errorFile)
	    # Check the process exit code, print error information if it exists
	    if not retval == 0:
		errData = errorFile.read()
		raise Exception("Error executing command: " + repr(errData))
	     
if __name__=="__main__":
  main(sys.argv[1:])
