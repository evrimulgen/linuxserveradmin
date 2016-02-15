#! /bin/bash
# Linux Server Administration Tool
# ilker Ozcan

APACHE_PATH="/etc/apache2/"
SERVER_ADMIN="iletisim@ilkerozcan.com.tr"

echo "1. Add new domain"
echo "2. Activate domain"
echo "3. Deactivate domain"
echo "4. Add SLL Certificate"
echo "5. Test apache configration"
echo "Choose an action = "

read USERACTION

function createNewDomain
{
	echo "Creating user ..."
	
	local USER_HOME_DIR="/home/${2}"
	
	if [ ! -d "${USER_HOME_DIR}/" ]; then
		echo "Error - home directory not created for this user"
		exit 1
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


		<FilesMatch "\.(ico|jpg|jpeg|png|gif|js|css|swf|eot|svg|ttf|woff|webm|ogv|ogg|mp3|mp4)$">
			ExpiresActive On
			ExpiresDefault "access plus 14 days"
        </FilesMatch>
		
		#<Directory "${USER_HOME_DIR}/cgi-bin">
			#Options +FollowSymLinks +ExecCGI
			#AddHandler cgi-script .cgi .py
		#</Directory>

		#ProxyPass /media !
		#Alias /media ${USER_HOME_DIR}/Public_html/media
		#ProxyPass /content !
		#Alias /content ${USER_HOME_DIR}/Public_html/content
		#ProxyPass /server-admin !
		#Alias /server-admin ${USER_HOME_DIR}/cgi-bin/serverAdmin.py
		#ProxyPass /favicon.ico !
		#Alias /favicon.ico ${USER_HOME_DIR}/Public_html/content/site/favicon.ico
		#ProxyPass /robots.txt !
		#Alias /robots.txt ${USER_HOME_DIR}/Public_html/content/site/robots.txt
		
		#ProxyPass / http://127.0.0.1:30000/
		#ProxyPassReverse / http://127.0.0.1:30000/
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

function createSSLDomain
{
	local USER_HOME_DIR="/home/${3}"
	
	if [ ! -d "${USER_HOME_DIR}/" ]; then
		echo "Error - home directory not found for this user"
		exit 1
	fi
	
	echo "Creating apache virtual host ... "
	
	local VIRTUALHOSTFILE="${APACHE_PATH}sites-available/ssl-${1}"
	
	cat > $VIRTUALHOSTFILE <<_EOFVHOSTFILE_

<VirtualHost ${4}:443>
        ServerAdmin $SERVER_ADMIN
        ServerName ${1}
        ServerAlias ${2}
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
CustomLog ${USER_HOME_DIR}/Logs/ssl-access.log combined
ErrorLog ${USER_HOME_DIR}/Logs/ssl-error.log


        <FilesMatch "\.(ico|jpg|jpeg|png|gif|js|css|swf|eot|svg|ttf|woff|webm|ogv|ogg|mp3|mp4)$">
                ExpiresActive On
                ExpiresDefault "access plus 14 days"
        </FilesMatch>
		
		SSLEngine on
		SSLProtocol all
		SSLCertificateFile ${USER_HOME_DIR}/SSL/${5}
        SSLCertificateKeyFile ${USER_HOME_DIR}/SSL/${6}
        SSLCACertificateFile ${USER_HOME_DIR}/SSL/${7}

</VirtualHost>

_EOFVHOSTFILE_
	
	echo "SSL Domain created. Administration domain name is: "
	echo ssl-${1}
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
4)	echo "Enter domain name:"
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
	echo "Enter SSL certificate file name:"
	read SSL_FILENAME
	echo ""
	echo "Enter SSL key file name:"
	read SSL_KEYNAME
	echo ""
	echo "Enter SSL CA certificate file name:"
	read SSL_CAFILENAME
	echo ""
	createSSLDomain $DOMAIN_NAME $DOMAIN_ALIAS $DOMAIN_USER $DOMAIN_IP $SSL_FILENAME $SSL_KEYNAME $SSL_CAFILENAME
	;;
5)	echo "Testing apache configration ..."
	/usr/sbin/apache2ctl -t
	;;
*)	echo "Invalid operation!"
	;;
esac