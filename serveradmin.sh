#! /bin/bash
# Linux Server Administration Tool
# ilker Ozcan

APACHE_PATH="/etc/apache2/"
SERVER_ADMIN="info@projecalide.com"

echo "1. Add new domain"
echo "2. Activate domain"
echo "3. Deactivate domain"
echo "4. Add subdomain"
echo "5. Test apache configration"
echo "6. Apply Apache + PHP-FPM configration"
echo "7. Check PHP-FPM status"
echo "8. Delete user"
echo "Choose an action = "

read USERACTION

function createNewDomain
{
	echo "Creating user ..."
	
	adduser $2
	usermod -a -G "www-data" $2
	usermod -g "www-data" $2
	
	local USER_HOME_DIR="/home/${2}"
	
	if [ ! -d "${USER_HOME_DIR}/" ]; then
		echo "Error - home directory not created for this user"
	else
		echo "Creating user home directory ... "
		mkdir "${USER_HOME_DIR}/cgi-bin"
		chown "${2}:www-data" "${USER_HOME_DIR}/cgi-bin"
		
		mkdir "${USER_HOME_DIR}/Logs"
		chown "${2}:www-data" "${USER_HOME_DIR}/Logs"
		
		mkdir "${USER_HOME_DIR}/Public_ftp"
		chown "${2}:www-data" "${USER_HOME_DIR}/Public_ftp"
		
		mkdir "${USER_HOME_DIR}/Public_html"
		chown "${2}:www-data" "${USER_HOME_DIR}/Public_html"
		
		mkdir "${USER_HOME_DIR}/SSL"
		chown "${2}:www-data" "${USER_HOME_DIR}/SSL"
	fi
	
	echo "Creating apache virtual host ... "
	
	local VIRTUALHOSTFILE="${APACHE_PATH}sites-available/www.${1}"
	
	cat > $VIRTUALHOSTFILE <<_EOFVHOSTFILE_

<VirtualHost ${3}:80>
        ServerAdmin $SERVER_ADMIN
        ServerName www.${1}
        ServerAlias ${1}
        DocumentRoot ${USER_HOME_DIR}/Public_html

        <Directory />
                Options -Indexes -FollowSymLinks -MultiViews
                AllowOverride All
                Order allow,deny
                Require all granted
                Allow from all
        </Directory>

        DirectoryIndex index.html index.htm index.php

        <Directory "${USER_HOME_DIR}/Public_html">
                Options +Indexes +FollowSymLinks
        </Directory>

LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" combined
CustomLog ${USER_HOME_DIR}/Logs/access.log combined
ErrorLog ${USER_HOME_DIR}/Logs/error.log


        <FilesMatch "\.(ico|jpg|jpeg|png|gif|js|css|swf|eot|swg|ttf|woff)$">
                ExpiresActive On
                ExpiresDefault "access plus 14 days"
        </FilesMatch>
</VirtualHost>

_EOFVHOSTFILE_
	
	echo "Domain created."
}

function activateDomain
{
	local DOMAINFILE="${APACHE_PATH}sites-available/${1}"
	local DOMAINLINK="${APACHE_PATH}sites-enabled/${1}.conf"

	if [ ! -f $DOMAINFILE ]; then
		echo "Domain not registered this web server!"
	else
		ln -s $DOMAINFILE $DOMAINLINK
		echo "Domain activated."
	fi
}

function deactivateDomain
{
	local DOMAINFILE="${APACHE_PATH}sites-enabled/${1}.conf"

	if [ ! -f $DOMAINFILE ]; then
		echo "Domain not registered this web server!"
	else
		rm $DOMAINFILE
		echo "Domain deactivated."
	fi
}

function createSubDomain
{
	local USER_HOME_DIR="/home/${3}"
	
	if [ ! -d "${USER_HOME_DIR}/" ]; then
		echo "Error - home directory not found for this user"
	else
		echo "Creating subdomain directory ... "
		
		mkdir "${USER_HOME_DIR}/${1}"
		chown "${3}:www-data" "${USER_HOME_DIR}/${1}"
		
		mkdir "${USER_HOME_DIR}/${1}/cgi-bin"
		chown "${3}:www-data" "${USER_HOME_DIR}/${1}/cgi-bin"
		
		mkdir "${USER_HOME_DIR}/${1}/Logs"
		chown "${3}:www-data" "${USER_HOME_DIR}/${1}/Logs"
		
		mkdir "${USER_HOME_DIR}/${1}/Public_ftp"
		chown "${3}:www-data" "${USER_HOME_DIR}/${1}/Public_ftp"
		
		mkdir "${USER_HOME_DIR}/${1}/Public_html"
		chown "${3}:www-data" "${USER_HOME_DIR}/${1}/Public_html"
	fi
	
	echo "Creating apache virtual host ... "
	
	local VIRTUALHOSTFILE="${APACHE_PATH}sites-available/${1}.${2}"
	
	cat > $VIRTUALHOSTFILE <<_EOFVHOSTFILE_

<VirtualHost ${4}:80>
        ServerAdmin $SERVER_ADMIN
        ServerName ${1}.${2}
        ServerAlias ${1}.${2}
        DocumentRoot ${USER_HOME_DIR}/${1}/Public_html

        <Directory />
                Options -Indexes -FollowSymLinks -MultiViews
                AllowOverride All
                Order allow,deny
                Require all granted
                Allow from all
        </Directory>

        DirectoryIndex index.html index.htm index.php

        <Directory "${USER_HOME_DIR}/${1}/Public_html">
                Options +Indexes +FollowSymLinks
        </Directory>

LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" combined
CustomLog ${USER_HOME_DIR}/${1}/Logs/access.log combined
ErrorLog ${USER_HOME_DIR}/${1}/Logs/error.log


        <FilesMatch "\.(ico|jpg|jpeg|png|gif|js|css|swf|eot|swg|ttf|woff)$">
                ExpiresActive On
                ExpiresDefault "access plus 14 days"
        </FilesMatch>
</VirtualHost>

_EOFVHOSTFILE_
	
	echo "Subdomain created."
}

function deleteUser
{
	userdel -r $1
}

case "$USERACTION" in

1)	echo "Enter domain alias:"
	read DOMAIN_ALIAS
	echo ""
	echo "Enter domain user name:"
	read DOMAIN_USER
	echo ""
	echo "Enter domain ip address:"
	read DOMAIN_IP
	echo ""
	createNewDomain $DOMAIN_ALIAS $DOMAIN_USER $DOMAIN_IP
	;;
2)	echo  "Enter domain name: "
	read DOMAINNAME
	echo ""
	activateDomain $DOMAINNAME
	;;
3)	echo  "Enter domain name: "
	read DOMAINNAME
	echo ""
	deactivateDomain $DOMAINNAME
	;;
4)	echo "Enter sub domain name:"
	read DOMAIN_NAME
	echo ""
	echo "Enter domain alias:"
	read DOMAIN_ALIAS
	echo ""
	echo "Enter domain user name:"
	read DOMAIN_USER
	echo ""
	echo "Enter domain ip address:"
	read DOMAIN_IP
	echo ""
	createSubDomain $DOMAIN_NAME $DOMAIN_ALIAS $DOMAIN_USER $DOMAIN_IP
	;;
5)	echo "Testing apache configration ..."
	/usr/sbin/apache2ctl -t
	;;
6)	echo "Applying apache - PHP-FPM configration ..."
	service apache2 restart
	service php-fpm restart
	;;
7)	echo "Checkişng PHP-FPM status ..."
	service php-fpm status
	;;
8)	echo  "Enter user name: "
	read USERNAME
	echo ""
	deleteUser $USERNAME
	;;
*)	echo "Invalid operation!"
	;;
esac


