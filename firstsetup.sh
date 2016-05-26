#!/usr/bin/env bash

adduser administrator

echo "Creating root user ..."
#USER_ADMIN_EXISTS=false
#getent passwd administrator >/dev/null 2>&1 && USER_ADMIN_EXISTS=true

#if [ $USER_ADMIN_EXISTS ];
#then
	#echo "User administrator exists"
#else
	adduser administrator
	echo "administrator	ALL=(ALL:ALL) NOPASSWD:ALL" >> "/etc/sudoers"
#fi

GROUP_WWW_EXISTS=false
getent group www-data >/dev/null 2>&1 && GROUP_WWW_EXISTS=true
if [ ! $GROUP_WWW_EXISTS ];
then
	groupadd www-data
fi

usermod -g www-data administrator

if [ ! -d /home/administrator/Logs ];
then
	mkdir /home/administrator/Logs
fi

if [ ! -d /home/administrator/SSL ];
then
	mkdir /home/administrator/SSL
fi

if [ ! -d /home/administrator/Public_html ];
then
	mkdir /home/administrator/Public_html
fi

if [ ! -d /home/administrator/Config ];
then
	mkdir /home/administrator/Config
fi

find /home/administrator/ -type d -exec chown administrator:www-data {} \;
#chown root:root /home/administrator/
chmod 755 /home/administrator/

apt-get install landscape-common

echo "Do you want to install webmin ? (y/n):"
read INSTALL_WEBMIN

if test "$INSTALL_WEBMIN" = "y"; then

	sudo sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
	wget -qO - http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
	sudo apt-get update
	sudo apt-get install webmin

fi