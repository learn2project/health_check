#!/bin/bash

##Make sure you are running as root
USER=`whoami`
if [ $USER != 'root' ]; then
	echo "You need to be root to run this script"
	echo "Exiting..."
	exit 1
fi
#Install Tomcat Server from http://mirrors.ibiblio.org/apache/tomcat/tomcat-7/v7.0.62/bin/apache-tomcat-7.0.62.tar.gz
##Figure out java location and version
which java > /dev/null 2>&1
if [ $? -eq 0 ]; then
	JAVA_PATH=`which java`
	JAVA_VER=`java -version 2>&1 | head -1 | cut -d. -f2`
	if [ $JAVA_VER -lt 6 ]; then
		echo "Your current java version is $JAVA_VER"
		echo "You need java version 6 or greater"
		echo "Exiting..."
		exit 1
	fi
	
else
	echo "You don't have Java installed. Please install Java version greater than 6 to continue"
	echo "Exiting..."
	exit 1
fi
##Figure out tomcat home
TOMCAT_HOME=" "
[ ! -d $TOMCAT_HOME ] || TOMCAT_HOME="/var/tomcat"
##Make sure you have wget
which wget > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "You do not have wget installed"
	echo "Please install wget and try again"
	exit 1
fi
##Download the tomcat archive
echo "Downloading tomcat..."
cd /tmp/
rm -rf apache-tomcat-7.0.62*
wget http://mirrors.ibiblio.org/apache/tomcat/tomcat-7/v7.0.62/bin/apache-tomcat-7.0.62.tar.gz
tar -xzf apache-tomcat-7.0.62.tar.gz
cp -pr /tmp/apache-tomcat-7.0.62/ $TOMCAT_HOME

#Configure Tomcat Server to start with http port as 80,
echo "Configuring tomcat..."
sed -ie 's,8080,80,g' $TOMCAT_HOME/conf/server.xml

#Install Mysql Database 
echo "Installing MySQL..."
yum -q -y install mysql-server*
service mysqld start > /dev/null 2>&1
service mysqld stop > /dev/null 2>&1
#Reset mysql root user password to welcome1 and run the provided Sql Script http://54.202.69.46/dbsetup.sql
echo "Changing MySQL root password..."
echo "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('welcome1');" > /tmp/mysql_root
mysqld_safe --init-file /tmp/mysql_root &
sleep 10
rm -f /tmp/mysql_root
##Download the sql script and run 
echo "Importing DBs..."
cd /tmp/
rm -f dbsetup.sql
wget http://54.202.69.46/dbsetup.sql
mysql -u root -pwelcome1 < dbsetup.sql
#Deploy the given Application on tomcat  http://54.202.69.46/petclinic.war
##Download petclinic.war
echo "Deploying petclinic war file..."
cd $TOMCAT_HOME/webapps
wget http://54.202.69.46/petclinic.war
#Start the server.
##Start using catalina.sh
cd $TOMCAT_HOME/bin
./catalina.sh start > /dev/null 2>&1
sleep 5
./catalina.sh stop 10 -force> /dev/null 2>&1
#Configure the application with data
base, this can be done by replacing %DB_TIER_IP% with localhost in WEB-INF/classes/jdbc.properties file of the application.
echo "Configuring tomcat for DB..."
sed -ie 's,%DB_TIER_IP%,localhost,g' $TOMCAT_HOME/webapps/petclinic/WEB-INF/classes/jdbc.properties
sed -ie 's,jdbc.password=pc,jdbc.password=welcome1,g' $TOMCAT_HOME/webapps/petclinic/WEB-INF/classes/jdbc.properties
sed -ie 's,jdbc.username=pc,jdbc.username=root,g' $TOMCAT_HOME/webapps/petclinic/WEB-INF/classes/jdbc.properties
##ReStart using catalina.sh
cd $TOMCAT_HOME/bin
echo "Starting server..."
./catalina.sh start > /dev/null 2>&1
echo "Deployment complete!"
