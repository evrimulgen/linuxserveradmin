#!/usr/bin/env bash

USAGE="USAGE:
 mailaccount [option] [type] [domain name]

options:
 add | a
 remove | r
 update | u

types:
 d | domain
 a | alias
 u | user

"

OPTION=-1
TYPE=-1

case $1 in
    add)
    OPTION=0
    ;;
    a)
    OPTION=0
    ;;
    remove)
    OPTION=1
    ;;
    r)
    OPTION=1
    ;;
    update)
    OPTION=2
    ;;
    u)
    OPTION=2
    ;;
    *)
	# unknown option
    ;;
esac

case $2 in
    domain)
    TYPE=0
    ;;
    d)
    TYPE=0
    ;;
    alias)
    TYPE=1
    ;;
    a)
    TYPE=1
    ;;
    user)
    TYPE=2
    ;;
    u)
    TYPE=2
    ;;
    *)
	# unknown option
    ;;
esac

DOMAIN_NAME_SIZE=${#3}

if [ $DOMAIN_NAME_SIZE -lt 3 ]; then

	echo -n "$USAGE"
	exit 0
fi

DOMAIN_NAME="$3"

if [ $OPTION -eq -1 ]; then

	echo -n "$USAGE"
	exit 0
fi

if [ $TYPE -eq -1 ]; then

	echo -n "$USAGE"
	exit 0
fi

PARSE_MAIL_DATABASE_CONFIG () {

	DBUSER=""
	DBPASSWORD=""
	DBHOST=""
	DBNAME=""

	while IFS='' read -r line || [[ -n "$line" ]]; do

		IFS=' = ' read -ra ADDR <<< "$line"

		case "${ADDR[0]}" in
		"user" )
			DBUSER="${ADDR[1]}"
		;;
		"password" )
			DBPASSWORD="${ADDR[1]}"
		;;
		"hosts" )
			DBHOST="${ADDR[1]}"
		;;
		"dbname" )
			DBNAME="${ADDR[1]}"
		;;
		esac;

	done < "./conf.d/mail.conf"
}

ADD_DOMAIN () {

	mysql --host="${DBHOST}" --user="${DBUSER}" --password="${DBPASSWORD}" --database="${DBNAME}" <<MYEOF
CALL addDomain('${DOMAIN_NAME}');
MYEOF
	echo ""
}

ADD_ALIAS () {

	mysql --host="${DBHOST}" --user="${DBUSER}" --password="${DBPASSWORD}" --database="${DBNAME}" <<MYEOF
CALL addAlias('${DOMAIN_NAME}', '$1', '$2');
MYEOF
	echo ""
}

ADD_USER () {

	mysql --host="${DBHOST}" --user="${DBUSER}" --password="${DBPASSWORD}" --database="${DBNAME}" <<MYEOF
CALL addUser('${DOMAIN_NAME}', '$1', '$2');
MYEOF
	echo ""
}

REMOVE_DOMAIN () {

mysql --host="${DBHOST}" --user="${DBUSER}" --password="${DBPASSWORD}" --database="${DBNAME}" <<MYEOF
CALL removeDomain('${DOMAIN_NAME}');
MYEOF
	echo ""
}

REMOVE_ALIAS () {

mysql --host="${DBHOST}" --user="${DBUSER}" --password="${DBPASSWORD}" --database="${DBNAME}" <<MYEOF
CALL removeAlias('${DOMAIN_NAME}', '$1');
MYEOF
	echo ""
}

REMOVE_USER () {

mysql --host="${DBHOST}" --user="${DBUSER}" --password="${DBPASSWORD}" --database="${DBNAME}" <<MYEOF
CALL removeUser('${DOMAIN_NAME}', '$1');
MYEOF
	echo ""
}

UPDATE_PASSWORD () {

mysql --host="${DBHOST}" --user="${DBUSER}" --password="${DBPASSWORD}" --database="${DBNAME}" <<MYEOF
CALL changePassword('${DOMAIN_NAME}', '$1', '$2');
MYEOF
	echo ""
}

if [ $TYPE -eq 0 ]; then


	if [ $OPTION -eq 0 ]; then

		PARSE_MAIL_DATABASE_CONFIG
		ADD_DOMAIN
	elif [ $OPTION -eq 1 ]; then

		echo "Are you sure remove domain ${DOMAIN_NAME} (y/N): "
		read REMOVE_DOMAIN_STATUS

		if test "$REMOVE_DOMAIN_STATUS" = "y"; then

			PARSE_MAIL_DATABASE_CONFIG
			REMOVE_DOMAIN
		fi

	fi

elif [ $TYPE -eq 1 ]; then

	if [ $OPTION -eq 0 ]; then


		echo "Source E-Mail address: "
		read SOURCE_MAIL
		echo ""
		echo "Destination E-Mail address: "
		read DESTINATION_MAIL

		PARSE_MAIL_DATABASE_CONFIG
		ADD_ALIAS "$SOURCE_MAIL" "$DESTINATION_MAIL"
	elif [ $OPTION -eq 1 ]; then

		echo "Source E-Mail address: "
		read SOURCE_MAIL
		echo ""

		echo "Are you sure remove alias ${SOURCE_MAIL} (y/N): "
		read REMOVE_DOMAIN_STATUS

		if test "$REMOVE_DOMAIN_STATUS" = "y"; then

			PARSE_MAIL_DATABASE_CONFIG
			REMOVE_ALIAS "$SOURCE_MAIL"
		fi

	fi

elif [ $TYPE -eq 2 ]; then

	if [ $OPTION -eq 0 ]; then


		echo "E-Mail address: "
		read SOURCE_MAIL
		echo ""
		echo "Password: "
		read PASSWORD

		ENCRYPTED_PASSWORD="$(./bin/IOServerManagerUtils -epwd -ppwd ${PASSWORD})"

		PARSE_MAIL_DATABASE_CONFIG
		ADD_USER "$SOURCE_MAIL" "$ENCRYPTED_PASSWORD"
	elif [ $OPTION -eq 1 ]; then

		echo "E-Mail address: "
		read SOURCE_MAIL
		echo ""

		echo "Are you sure remove user ${SOURCE_MAIL} (y/N): "
		read REMOVE_DOMAIN_STATUS

		if test "$REMOVE_DOMAIN_STATUS" = "y"; then

			PARSE_MAIL_DATABASE_CONFIG
			REMOVE_USER "$SOURCE_MAIL"
		fi

	elif [ $OPTION -eq 2 ]; then

		echo "E-Mail address: "
		read SOURCE_MAIL
		echo ""
		echo "Password: "
		read PASSWORD

		ENCRYPTED_PASSWORD="$(./bin/IOServerManagerUtils -epwd -ppwd ${PASSWORD})"

		PARSE_MAIL_DATABASE_CONFIG
		UPDATE_PASSWORD "$SOURCE_MAIL" "$ENCRYPTED_PASSWORD"
	fi

fi

