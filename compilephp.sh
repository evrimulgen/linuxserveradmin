#!/usr/bin/env bash

USAGE="USAGE:
 compilephp [options] [args]

options:
 install-dependencies
 compile

args:
 --prefix=[path]
 --sourcedir=[path]
 --update-binaries
 --install-fpm-service

"

UbuntuInstallPackageIfNotExists () {

	PACKAGE_INSTALLED=$(apt-cache policy $1)
	if [[ $PACKAGE_INSTALLED == *"Installed: (none)"* ]]
	then
        apt-get install -y $1
	else
        echo "$1 already installed!"
	fi
}

OTHER_ARGS_COUNT=0
INSTALL_DEPENDENCIES="no"
CONFIGURE="no"
UPDATE_BINARIES="no"
INSTALL_FPM_SERVICE="no"

for i in "$@"
do
case $i in
    --prefix=*)
    PREFIX="${i#*=}"
    shift # past argument=value
    ;;
    --sourcedir=*)
    SOURCEDIR="${i#*=}"
    shift # past argument=value
    ;;
    install-dependencies)
	INSTALL_DEPENDENCIES="yes"
    shift # past argument=value
    ;;
    compile)
	CONFIGURE="yes"
	shift
	;;
	--update-binaries)
	UPDATE_BINARIES="yes"
	shift
	;;
	--install-fpm-service)
	INSTALL_FPM_SERVICE="yes"
	shift
	;;
    *)
    OTHER_ARGS[$OTHER_ARGS_COUNT]=$i
    OTHER_ARGS_COUNT=$((OTHER_ARGS_COUNT + 1))
	# unknown option
    ;;
esac
done

if test "$INSTALL_DEPENDENCIES" = "yes"; then

	UbuntuInstallPackageIfNotExists "build-essential"
	UbuntuInstallPackageIfNotExists "libxml2-dev"
	UbuntuInstallPackageIfNotExists "libssl-dev"
	UbuntuInstallPackageIfNotExists "libcurl4-openssl-dev"
	UbuntuInstallPackageIfNotExists "pkg-config"
	UbuntuInstallPackageIfNotExists "libbz2-dev"
	UbuntuInstallPackageIfNotExists "libjpeg-dev"
	UbuntuInstallPackageIfNotExists "libpng12-dev"
	UbuntuInstallPackageIfNotExists "libxpm-dev"
	UbuntuInstallPackageIfNotExists "libfreetype6-dev"
	UbuntuInstallPackageIfNotExists "libc-client-dev"
	UbuntuInstallPackageIfNotExists "libmcrypt-dev"
	UbuntuInstallPackageIfNotExists "libtidy-dev"
	UbuntuInstallPackageIfNotExists "libkrb5-dev"
	UbuntuInstallPackageIfNotExists "libwebp-dev"
	UbuntuInstallPackageIfNotExists "libxslt1-dev"

    exit 0
fi

if [ -z ${PREFIX+x} ]; then
	echo -n "$USAGE"
	exit 1
fi

if [ -z ${SOURCEDIR+x} ]; then
	echo -n "$USAGE"
	exit 1
fi


if test "$CONFIGURE" = "yes"; then

	CONFIGURE_COMMAND="./configure --prefix=${PREFIX} \
--disable-fileinfo --enable-bcmath --enable-calendar --enable-ftp --enable-libxml --enable-mbstring \
--enable-sockets --enable-zip --enable-gd-native-ttf --enable-gd-jis-conv --enable-soap --enable-pcntl \
--enable-sysvmsg --enable-sysvsem --enable-sysvshm --enable-exif --enable-wddx \
--with-curl --with-gettext --with-mcrypt --with-openssl --with-pcre-regex --with-pic --with-zlib \
--with-gd --with-bz2 --with-jpeg-dir=/usr/lib --with-png-dir=/usr/lib --with-xpm-dir=/usr/lib \
--with-freetype-dir=/usr/include/freetype2 --with-kerberos --with-iconv-dir --with-mhash \
--with-xmlrpc --with-tidy \
--with-mysqli --enable-pdo=shared --with-pdo-mysql=shared --with-pdo-sqlite=shared --enable-mysqlnd \
--with-tsrm-pthreads --enable-opcache --enable-maintainer-zts \
--enable-fpm"

	for i in "${OTHER_ARGS[@]}"
	do
		CONFIGURE_COMMAND="$CONFIGURE_COMMAND ${i}"
	done

	cd $SOURCEDIR
	eval $CONFIGURE_COMMAND

	make --directory=${SOURCEDIR}
	make --directory=${SOURCEDIR} install

	if test "$UPDATE_BINARIES" = "yes"; then
	ln -s ${PREFIX}/bin/php /usr/local/bin
	ln -s ${PREFIX}/bin/php-cgi /usr/local/bin
	ln -s ${PREFIX}/bin/php-config /usr/local/bin
	ln -s ${PREFIX}/bin/phpize /usr/local/bin
	ln -s ${PREFIX}/bin/phpdbg /usr/local/bin
	ln -s ${PREFIX}/bin/phar.phar /usr/local/bin/phar
	fi

	if test "$INSTALL_FPM_SERVICE" = "yes"; then
	cp ${SOURCEDIR}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
	chmod +x /etc/init.d/php-fpm
	update-rc.d php-fpm defaults
	fi
fi