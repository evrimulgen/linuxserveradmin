#!/usr/bin/env bash

USAGE="USAGE:
 generatessl [args] [alt name 1] [alt name 2] ...

 --prefix=[path]
 --country=[country code]
 --locality=[locality name]
 --organization=[organization name]
 --common-name=[common name]
 --email-address=[e-mail address]

 "

ALT_NAME_COUNT=0

for i in "$@"
do
case $i in
    --prefix=*)
    PREFIX="${i#*=}"
    shift # past argument=value
    ;;
    --country=*)
    COUNTRY="${i#*=}"
    shift # past argument=value
    ;;
    --locality=*)
    LOCALITY="${i#*=}"
    shift # past argument=value
    ;;
    --organization=*)
    ORGANIZATION="${i#*=}"
    shift # past argument=value
    ;;
    --common-name=*)
    COMMONNAME="${i#*=}"
    shift # past argument=value
    ;;
    --email-address=*)
    EMAIL="${i#*=}"
    shift # past argument=value
    ;;
    *)
    ALT_NAMES[$ALT_NAME_COUNT]=$i
    ALT_NAME_COUNT=$((ALT_NAME_COUNT + 1))
	# unknown option
    ;;
esac
done

if [ -z ${PREFIX+x} ]; then
	echo -n "$USAGE"
	exit 1
fi

if [ -z ${COUNTRY+x} ]; then
	echo -n "$USAGE"
	exit 1
fi

if [ -z ${LOCALITY+x} ]; then
	echo -n "$USAGE"
	exit 1
fi

if [ -z ${ORGANIZATION+x} ]; then
	echo -n "$USAGE"
	exit 1
fi

if [ -z ${COMMONNAME+x} ]; then
	echo -n "$USAGE"
	exit 1
fi


if [ -z ${EMAIL+x} ]; then
	echo -n "$USAGE"
	exit 1
fi

read -r -d '' CSR_OPTIONS << CSREOF
[ req ]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_ca
prompt = no
[ req_distinguished_name ]
countryName = ${COUNTRY}
localityName = ${LOCALITY}
organizationalUnitName = ${ORGANIZATION}
commonName = ${COMMONNAME} Authory
emailAddress = ${EMAIL}

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier=keyid,issuer
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
CSREOF

echo "$CSR_OPTIONS" > "${PREFIX}ca_config"

read -r -d '' CERT_OPTIONS << CREOF
[ req ]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[ req_distinguished_name ]
countryName = ${COUNTRY}
localityName = ${LOCALITY}
organizationalUnitName = ${ORGANIZATION}
commonName = ${COMMONNAME}
emailAddress = ${EMAIL}

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[ alt_names ]
CREOF

echo "$CERT_OPTIONS" > "${PREFIX}cert_config"

ALT_NAME_INDEX=1
for i in "${ALT_NAMES[@]}"
do
	DNS_STRING="DNS.${ALT_NAME_INDEX} = ${i}"
	echo "$DNS_STRING" >> "${PREFIX}cert_config"
	ALT_NAME_INDEX=$((ALT_NAME_INDEX + 1))
done

openssl genrsa -des3 -passout pass:1234 -out ${PREFIX}ca.key 2048
openssl req -new -x509 -sha256 -days 730 -key ${PREFIX}ca.key -out ${PREFIX}ca.cer -config ${PREFIX}ca_config -passin pass:1234
openssl genrsa -des3 -passout pass:1234 -out ${PREFIX}certificate_des.key 2048
openssl req -new -key ${PREFIX}certificate_des.key -out ${PREFIX}certificate.csr -config ${PREFIX}cert_config -passin pass:1234
openssl x509 -req -sha256 -days 730 -in ${PREFIX}certificate.csr -CA ${PREFIX}ca.cer -CAkey ${PREFIX}ca.key -set_serial 01 -out ${PREFIX}certificate.cer -extensions v3_req -extfile ${PREFIX}cert_config -passin pass:1234
openssl rsa -in ${PREFIX}certificate_des.key -out ${PREFIX}certificate.key -passin pass:1234
cat ${PREFIX}certificate.cer ${PREFIX}ca.cer > ${PREFIX}certificate_with_ca.cer
openssl x509 -in ${PREFIX}certificate_with_ca.cer -text -noout