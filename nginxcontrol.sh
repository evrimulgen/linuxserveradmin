#!/usr/bin/env bash

USAGE="USAGE:
 nginxcontrol [domain name] [activate|deactivate]

"

COMMAND_EXECUTED="n"

if test "$2" = "activate"; then

	ln -s /etc/nginx/sites-available/$1.conf /etc/nginx/sites-enabled/$1.conf
	COMMAND_EXECUTED="y"

fi

if test "$2" = "deactivate"; then

	rm -f /etc/nginx/sites-enabled/$1.conf
	COMMAND_EXECUTED="y"

fi

if test "$COMMAND_EXECUTED" = "n"; then
	echo -n "$USAGE"
fi