#!/usr/bin/env bash

USAGE="USAGE:
 createnginxhost [domain name] [user name] [args]

args:
 --nginxconfpath=[path]
 --phpsocketpath=[path]

"

DOMAIN_NAME_SIZE=${#1}
USER_NAME_SIZE=${#2}

if [ $DOMAIN_NAME_SIZE -lt 3 ]; then

	echo -n "$USAGE"
	exit 0
fi

if [ $USER_NAME_SIZE -lt 3 ]; then

	echo -n "$USAGE"
	exit 0
fi

NGINX_CONF_PATH="/etc/nginx/sites-available"
PHP_SOCKET_PATH="/var/run/php-fpm.sock"

for i in "$@"
do
case $i in
    --nginxconfpath=*)
    NGINX_SOCKET_PATH="${i#*=}"
    shift # past argument=value
    ;;
    --phpsocketpath=*)
    PHP_SOCKET_PATH="${i#*=}"
    shift # past argument=value
    ;;
    *)
	# unknown option
    ;;
esac
done

echo "Creating user ..."
#USER_EXISTS=false
#getent passwd $2 >/dev/null 2>&1 && USER_EXISTS=true

#if [ USER_EXISTS ];
#then
#	echo "User $2 exists"
#	exit 0
#else
#	adduser $2
#fi
adduser $2

GROUP_WWW_EXISTS=false
getent group www-data >/dev/null 2>&1 && GROUP_WWW_EXISTS=true
if [ ! GROUP_WWW_EXISTS ];
then
	groupadd www-data
fi

usermod -g www-data $2

if [ ! -d /home/$2/Logs ];
then
	mkdir /home/$2/Logs
fi

if [ ! -d /home/$2/SSL ];
then
	mkdir /home/$2/SSL
fi

if [ ! -d /home/$2/Public_html ];
then
	mkdir /home/$2/Public_html
fi

if [ ! -d /home/$2/Config ];
then
	mkdir /home/$2/Config
fi

find /home/$2/ -type d -exec chown $2:www-data {} \;
chown root:root /home/$2/
chmod 755 /home/$2/

NGINX_HOST_FILE="${NGINX_CONF_PATH}/${1}.conf"
cat > $NGINX_HOST_FILE <<EOM
#Home dir is
# /home/$2 root:root 755
# /home/$2/SSL $2:www-data  775
# /home/$2/Config $2:www-data  775
# /home/$2/Logs $2:www-data  775
# /home/$2/Public_html $2:www-data  775
# /home/$2/tmp $2:www-data  775

# redirect if url does not start www
#server
#{
	#listen 80;
	#listen 443 ssl;
	#server_name $1;

	#ssl on;
	#ssl_certificate /home/$2/SSL/$2.cer;
	#ssl_certificate_key /home/$2/SSL/$2.key;
	#ssl_session_timeout 20m;

	#return 301 $schema://$1\$is_args\$args;
#}

#map \$http_origin \$cors_header {
	#default "";
	#"~^https?://[^/]+\.$1\.com(:[0-9]+)?\$" "\$http_origin";
	#"~^http?://[^/]+\.$1\.com(:[0-9]+)?\$" "\$http_origin";
#}

# production HTTP & Secure server
server
{
	listen 80;
	listen 443 ssl;
	server_name $1 www.$1 prod.$1;
	charset utf-8;
	access_log /home/$2/Logs/$2-access.log;
	error_log /home/$2/Logs/$2-error.log;
	root /home/$2/Public_html;
	index index.php index.html index.htm;

	#ssl on;
	#ssl_certificate /home/$2/SSL/$2.crt;
	#ssl_certificate_key /home/$2/SSL/$2.key;

	gzip on;
	gzip_types application/json image/jpeg image/pjpeg image/png application/octet-stream text/css text/javascript application/javascript application/x-javascript;

	location /
	{
		index app.php;

		location ~ ^/\.(ht*|git|svn) {
			return 403;
		}

		location ~ /\. {
			access_log off;
			log_not_found off;
			deny all;
		}

		location ~ \~\$ {
			return 403;
		}

		location ~ ^/(app/*|bin*|src*|vendor*|composer*|README*)\$ {
			return 403;
		}

		location ~ ^/server-status {
			return 403;
		}

		#location ~ ^/admin(/|\$) {
			#auth_basic "Restricted";
			#auth_basic_user_file /home/$2/Config/.htpasswd;
			#try_files $uri $uri/ @$2FastCgi_Prod;
		#}

		try_files \$uri \$uri/ @$2FastCgi_Prod;
	}

	location @$2FastCgi_Prod {

		#add_header Access-Control-Allow-Origin \$cors_header;

		# Check if a file or directory index file exists, else route it to index.php.
		try_files \$uri \$uri/ /app.php\$is_args\$args;

		# if request is static file
		expires max;
		access_log off;
		log_not_found off;
	}


	location ~ \.php(/|\$) {
		fastcgi_pass unix:$PHP_SOCKET_PATH;
		fastcgi_split_path_info ^(.+\.php)(/.*)\$;
		include fastcgi_params;
		fastcgi_buffers 16 16k;
		fastcgi_buffer_size 32k;
		fastcgi_index index.php;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		fastcgi_param HTTPS \$https;

		# Prevents URIs that include the front controller. This will 404:
		# http://domain.tld/app.php/some-path
		# Remove the internal directive to allow URIs like this
		internal;
	}


	#error_page 404 http://$server_name/error404/;
	#error_page 403 http://$server_name/homepage/forbiddenPage/;
}

EOM
