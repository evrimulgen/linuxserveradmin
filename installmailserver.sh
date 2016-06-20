#!/usr/bin/env bash

USAGE="USAGE:
 installmailserver [option]

options:
 installpackages
 installdatabase

"

COMMAND_EXECUTED="n"

if test "$1" = "installpackages"; then

	apt-get install postfix postfix-mysql
	apt-get install dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql libsasl2-modules
	apt-get install spamassassin spamc opendkim

	adduser spamd --disabled-login
	groupadd -g 5000 vmail
	useradd -g vmail -u 5000 vmail -d /var/mail

	if [ ! -d "/var/mail" ];
	then
		mkdir /var/mail
	fi

	chown -R vmail:vmail /var/mail

	if [ ! -d "/etc/dovecot" ];
	then
		mkdir /etc/dovecot
	fi

	chown -R vmail:dovecot /etc/dovecot
	chmod -R o-rwx /etc/dovecot

	if [ ! -d "/var/mail/vhosts" ];
	then
		mkdir /var/mail/vhosts
	fi

	chmod 775 /var/mail/vhosts

	COMMAND_EXECUTED="y"
fi

if test "$1" = "installdatabase"; then

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

	mysql --host="${DBHOST}" --user="${DBUSER}" --password="${DBPASSWORD}" --database="${DBNAME}" <<MYEOF
CREATE TABLE IF NOT EXISTS virtual_domains ( id INT AUTO_INCREMENT,
	name VARCHAR(120) NOT NULL,
	PRIMARY KEY (id),
	UNIQUE KEY name_index (name)
) Engine=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS virtual_users (
	id INT AUTO_INCREMENT,
	domain_id INT NOT NULL,
	password VARCHAR(255) NOT NULL,
	email VARCHAR(255) NOT NULL,
	PRIMARY KEY (id),
	UNIQUE KEY email_index (email),
	CONSTRAINT v_users_domain_fnk FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) Engine=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE IF NOT EXISTS virtual_aliases (
	id INT AUTO_INCREMENT,
	domain_id INT NOT NULL,
	source varchar(255) NOT NULL,
	destination varchar(255) NOT NULL,
	PRIMARY KEY (id),
	UNIQUE KEY alias_index (source),
	CONSTRAINT v_aliases_domain_fnk
	FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP procedure IF EXISTS addDomain;
DELIMITER $$
CREATE PROCEDURE addDomain (
	in varpDomainName varchar(120)
)
BEGIN

	declare vardDomainExists int;
	select count(id) into vardDomainExists from virtual_domains where name = varpDomainName;
	if vardDomainExists > 0 then
		select 'Domain exists' as status;
	else
		insert into virtual_domains(name) values(varpDomainName);
		select concat('Domain ', varpDomainName, ' added. id = ', LAST_INSERT_ID()) as status;
	end if;
END
$$
DELIMITER ;

DROP procedure IF EXISTS addAlias;
DELIMITER $$
CREATE PROCEDURE addAlias (
	in varpDomainName varchar(120),
	in varpSourceMail varchar(255),
	in varpDestinationMail varchar(255)
)
BEGIN

	declare vardDomainId int default 0;
	declare vardSourceExists int default 0;

	select id into vardDomainId
	from virtual_domains where name = varpDomainName;

	if vardDomainId > 0 then

		select count(id) into vardSourceExists
		from virtual_aliases
		where source = varpSourceMail and domain_id = vardDomainId;

		if vardSourceExists > 0 then
			select concat('Alias ', varpSourceMail, ' exists!.') as status;
		else
			insert into virtual_aliases(domain_id, source, destination)
			values (vardDomainId, varpSourceMail, varpDestinationMail);
			select concat('Alias ', varpSourceMail, ' added. id = ', LAST_INSERT_ID()) as status;
		end if;

	else
		select concat('Domain ', varpDomainName, ' does not exists!.') as status;
	end if;

END
$$
DELIMITER ;

DROP procedure IF EXISTS addUser;
DELIMITER $$
CREATE PROCEDURE addUser (
	in varpDomainName varchar(120),
	in varpMail varchar(255),
	in varpPassword varchar(255)
)
BEGIN

	declare vardDomainId int default 0;
	declare vardSourceExists int default 0;

	select id into vardDomainId
	from virtual_domains where name = varpDomainName;

	if vardDomainId > 0 then

		select count(id) into vardSourceExists
		from virtual_users
		where email = varpMail and domain_id = vardDomainId;

		if vardSourceExists > 0 then
			select concat('User ', varpMail, ' exists!.') as status;
		else
			insert into virtual_users(domain_id, password, email)
			values (vardDomainId, varpPassword, varpMail);
			select concat('User ', varpMail, ' added. id = ', LAST_INSERT_ID()) as status;
		end if;

	else
		select concat('Domain ', varpDomainName, ' does not exists!.') as status;
	end if;

END
$$
DELIMITER ;

DROP procedure IF EXISTS removeDomain;
DELIMITER $$
CREATE PROCEDURE removeDomain (
	in varpDomainName varchar(120)
)
BEGIN

	declare vardDomainId int default 0;

	select id into vardDomainId
	from virtual_domains where name = varpDomainName;

	if vardDomainId > 0 then

		delete from virtual_aliases where domain_id = vardDomainId;
		delete from virtual_users where domain_id = vardDomainId;
	else
		select concat('Domain ', varpDomainName, ' does not exists!.') as status;
	end if;
END
$$
DELIMITER ;

DROP procedure IF EXISTS removeAlias;
DELIMITER $$
CREATE PROCEDURE removeAlias (
	in varpDomainName varchar(120),
	in varpSourceMail varchar(255)
)
BEGIN

	declare vardDomainId int default 0;

	select id into vardDomainId
	from virtual_domains where name = varpDomainName;

	if vardDomainId > 0 then

		delete from virtual_aliases where domain_id = vardDomainId and source = varpSourceMail;
	else
		select concat('Domain ', varpDomainName, ' does not exists!.') as status;
	end if;
END
$$
DELIMITER ;

DROP procedure IF EXISTS removeUser;
DELIMITER $$
CREATE PROCEDURE removeUser (
	in varpDomainName varchar(120),
	in varpSourceMail varchar(255)
)
BEGIN

	declare vardDomainId int default 0;

	select id into vardDomainId
	from virtual_domains where name = varpDomainName;

	if vardDomainId > 0 then

		delete from virtual_users where domain_id = vardDomainId and email = varpSourceMail;
	else
		select concat('Domain ', varpDomainName, ' does not exists!.') as status;
	end if;
END
$$
DELIMITER ;

DROP procedure IF EXISTS changePassword;
DELIMITER $$
CREATE PROCEDURE changePassword (
	in varpDomainName varchar(120),
	in varpMail varchar(255),
	in varpPassword varchar(255)
)
BEGIN

	declare vardDomainId int default 0;
	declare vardSourceExists int default 0;

	select id into vardDomainId
	from virtual_domains where name = varpDomainName;

	if vardDomainId > 0 then

		select count(id) into vardSourceExists
		from virtual_users
		where email = varpMail and domain_id = vardDomainId;

		if vardSourceExists = 0 then
			select concat('User ', varpMail, ' does not exists!.') as status;
		else
			# select CAST(ENCRYPT('gE4XKGKP', CONCAT('$6$', SUBSTRING(SHA(RAND()), -16))) as CHAR(1000) CHARACTER SET utf8);
			update virtual_users set password = varpPassword
			where domain_id = vardDomainId and email = varpMail;
			select concat('User ', varpMail, ' password updated') as status;
		end if;

	else
		select concat('Domain ', varpDomainName, ' does not exists!.') as status;
	end if;

END
$$
DELIMITER ;

MYEOF

	COMMAND_EXECUTED="y"
fi

if test "$COMMAND_EXECUTED" = "n"; then
	echo -n "$USAGE"
fi