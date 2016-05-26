#!/usr/bin/env bash

USAGE="USAGE:
 generatedkimkey [name] [path]

 "

CURRENT_ARG=0

for i in "$@"
do

    if test $CURRENT_ARG = 0; then
	NAME=$i
	fi

	if test $CURRENT_ARG = 1; then
    EXPORT_PATH=$i
    fi

	CURRENT_ARG=$((CURRENT_ARG + 1))
    #shift

done

if [ -z ${EXPORT_PATH+x} ]; then
	echo -n "$USAGE"
	exit 1
fi

if [ -z ${NAME+x} ]; then
	echo -n "$USAGE"
	exit 1
fi

openssl genrsa -out ${EXPORT_PATH}${NAME}.key 1024
openssl rsa -in ${EXPORT_PATH}${NAME}.key -pubout -out ${EXPORT_PATH}${NAME}.public.key
sudo chmod 600 ${EXPORT_PATH}${NAME}.key