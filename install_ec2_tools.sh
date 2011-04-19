#Installs all the necessary tools to use the ec2-start-test and ec2-kill-test scripts.
#Doesn't install the actual tools. Should probably add that as an option.
#Oh, and this wouldn't even work for anyone but me. Should probably fix that too..
#Modify path names?

sudo add-apt-repository "deb http://archive.canonical.com/ lucid partner"
sudo apt-get -y update

sudo apt-get -y install unzip sun-java6-jre

#Export variables to ~/.bashrc
#Need to check for each variable in ~/.bashrc. Grep?
RES=$(grep "EC2_HOME" ~/.bashrc)
if [ $? -ne 0 ]; then
  echo export EC2_HOME=$HOME/Dropbox/config/ec2/ec2-api-tools-1.4.2.4/ >> ~/.bashrc
else
  echo "EC2_HOME exists"
fi
RES=$(grep "EC2_CERT" ~/.bashrc)
if [ $? -ne 0 ]; then
  echo export EC2_CERT=$HOME/Dropbox/config/ec2/cert-3VJG2ORMUEMUWE2IZNQNZNH2IWS5HYEM.pem >> ~/.bashrc
else
  echo "EC2_CERT exists"
fi
RES=$(grep "EC2_PRIVATE_KEY" ~/.bashrc)
if [ $? -ne 0 ]; then
  echo export EC2_PRIVATE_KEY=$HOME/Dropbox/config/ec2/pk-3VJG2ORMUEMUWE2IZNQNZNH2IWS5HYEM.pem >> ~/.bashrc
else
  echo "EC2_PRIVATE_KEY exists"
fi
RES=$(grep "PATH" ~/.bashrc)
if [ $? -ne 0 ]; then
  echo export PATH=$PATH:$EC2_HOME/bin >> ~/.bashrc
else
  echo "PATH exists"
fi
RES=$(grep "JAVA_HOME" ~/.bashrc)
if [ $? -ne 0 ]; then
  echo export JAVA_HOME=/usr/lib/jvm/java-6-sun/jre >> ~/.bashrc
else
  echo "JAVA_HOME exists"
fi
RES=$(grep "EC2_DEFAULT_KEY" ~/.bashrc)
if [ $? -ne 0 ]; then
  echo export EC2_DEFAULT_KEY=$HOME/Dropbox/config/ec2/Default.pem >> ~/.bashrc
else
  echo "EC2_DEFAULT_KEY exists"
fi

echo "Installed environmental variables into ~/.bashrc. Please restart the terminal"
