#! /bin/bash -e

########################################################################
#
# this assumes you have launched an Ubuntu server on Amazon EC/2
# and you have:
#  - added a Shippable user to the EC/2 node via the instructions 
#    found at http://docs.shippable.com/integrations/deploy/nodeCluster/
#  - copied this script to the EC/2 instance
#  - connected via ssh with the 'ubuntu' user
#
# install multiple Tomcat instances on same EC/2 instance by running 
# script multiple times, with different values provided for TOMCAT_DIR
# 
# if multiple Tomcat instances, installed, you'll need to change the
# default Tomcat ports for additional instances
# 
########################################################################

TOMCAT_DIR=tomcat-prod
TOMCAT_MAJOR="8"
TOMCAT_VER="8.0.41"
TOMCAT_DOWNLOAD="http://mirrors.gigenet.com/apache/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VER/bin/apache-tomcat-$TOMCAT_VER.zip"

# create directory for tomcat
cd /opt
sudo mkdir $TOMCAT_DIR
cd $TOMCAT_DIR

# download and unzip tomcat, move files into TOMCAT_DIR
sudo wget $TOMCAT_DOWNLOAD 
sudo apt-get update
sudo apt-get install unzip
sudo unzip apache-tomcat-$TOMCAT_VER.zip
sudo mv apache-tomcat-$TOMCAT_VER/* . 

# create tomcat user/group
if [[ ! $(getent group tomcat) ]]; then
  sudo groupadd tomcat
  sudo useradd -g tomcat -s /bin/bash -d /opt/tomcat-prod tomcat
fi

# create tomweb user/group 
if [[ ! $(getent group tomweb) ]]; then
  sudo groupadd tomweb
  sudo useradd -g tomweb -s /bin/bash -d /opt/tomcat-prod tomweb
fi

# ensure scripts are executable and webapps folder is writeable
sudo chmod 755 /opt/$TOMCAT_DIR/bin/*.sh
sudo chmod 755 /opt/$TOMCAT_DIR/webapps/

# make tomweb owner of the tomcat files/directories
cd /opt
sudo chown -R tomweb.tomweb /opt/$TOMCAT_DIR/

# add the tomcat and shippable users to tomweb group
sudo usermod -a -G tomweb tomcat
if [[ $(getent passwd shippable) ]]; then
  sudo usermod -a -G tomweb shippable
else
  echo "Shippable user created. See http://docs.shippable.com/integrations/deploy/nodeCluster/ for instructions."
fi

# switch to tomcat user and start server
sudo su tomcat
/opt/$TOMCAT_DIR/bin/startup.sh
