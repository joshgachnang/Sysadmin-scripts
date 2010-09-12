#!/bin/bash

USER='josh'

# Ensure script is run as root
if [ "$(id -u)" != "0" ]; then
  echo "Script must be run as root."
  exit 1
fi

# Ensure Ubuntu One has already been signed into and synced.
if [ ! -d "/home/$USER/Ubuntu\ One" ]; then
  echo "Please login to Ubuntu One and start syncing first"
  echo "Then rerun this script."
  exit 1
fi

apt-get -y update && apt-get -y upgrade
apt-get -y install kate subversion eclipse powertop git-core gitosis flashplugin-nonfree
ln -s /home/$USER/Ubuntu\ One/programming/ /home/$USER/programming

#Link Documents to the Documents folder in 
rm -rf /home/josh/Documents
ln -s /home/josh/Ubuntu\ One/Documents/ /home/josh/Documents

#Install Chrome
echo "deb http://dl.google.com/linux/deb/ unstable non-free main" | sudo tee -a /etc/apt/sources.list > /dev/null
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo apt-get update && sudo apt-get install google-chrome-unstable

#Install Skype
echo "deb http://download.skype.com/linux/repos/debian/ stable non-free #Skype" | sudo tee -a /etc/apt/sources.list > /dev/null
gpg --keyserver pgp.mit.edu --recv-keys 0xd66b746e && gpg --export --armor 0xd66b746e  | sudo apt-key add -
sudo apt-get update && sudo apt-get install skype
