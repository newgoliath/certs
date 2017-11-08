#!/bin/bash

# create server certs for OpenShift classes.

# creates "loadbalancer.$GUID.$DOMAIN" 
#  and "*.apps.$GUID.$DOMAIN" certs by default
# creates whatever other named server certificates you'd like

# -d accepts a domain name.  example.opentlc.com
# -g accept a GUID. rdu1
# -h accept comma delimited hostnames (hostname or fqdn) NO SPACES for all named certs.
# -o output path

GUID="testguid"
DOMAINNAME="example.opentlc.com"
OUT_PATH="./ca/intermediate/newcerts/"

while getopts ":d:o:g:h:" opt ; do
	case $opt in
		d)
			echo "DOAMINANME: ${OPTARG}"
			DOMAINNAME="${OPTARG}"
      		;;
		g)
			echo "GUID = ${OPTARG}"
			GUID="${OPTARG}"
      		;;
		o)
			echo "OUT_PATH ${OPTARG}"
			OUT_PATH="${OPTARG}"
			;;
		h)
			echo "HOSTNAMES = $OPTARG" >&2
			HOSTNAMES="${OPTARG}"
		;;
	esac
done


##################
# VALIDATE VARIABLES

# validate domain name
host ${DOMAINNAME} || exit 1

# guid syntax check
if ! [[ "$GUID" =~ ^[[:alnum:]]+$ ]] 
then
    echo "FAILED: need alphnum guid"
    exit 1
fi

# check path
OUT_PATH="${OUT_PATH}/${GUID}"
if ! [[ -d ${OUT_PATH} ]] 
then	
    if ! $( mkdir -p ${OUT_PATH} )
    then
        echo "FAILED: Cant acces or make directory ${OUT_PATH}" 
        exit 1
    fi
fi
GUID_DOMAIN="${GUID}.${DOMAINNAME}"
HOSTNAMES="${HOSTNAMES},certtest.${GUID_DOMAIN},*.apps.${GUID_DOMAIN}"
IFS=',' read -r -a HOSTNAMES_A <<< "${HOSTNAMES}"

##################
# create server certs

# clean up old cert indexes to prevent collisions
#find . -name 'index.txt*' -delete
rm ca/intermediate/index.txt
touch ca/intermediate/index.txt

for SERVER_NAME in "${HOSTNAMES_A[@]}"
do
    [[ -z ${SERVER_NAME} ]] && continue
    export cn="${SERVER_NAME}"

    # turn * into word "wildcard"
    SERVER_NAME=${SERVER_NAME/\*/"wildcard"}

    echo --- creating the SERVER KEY
    openssl genrsa -out ${OUT_PATH}/${SERVER_NAME}.key.pem 2048

    echo --- creating the SERVER CSR
    # server key and certificate
    openssl req -nodes -new -sha256 \
          -config template.server.cnf -extensions server_cert \
          -key ${OUT_PATH}/${SERVER_NAME}.key.pem \
          -out ${OUT_PATH}/${SERVER_NAME}.csr.pem

    echo --- creating the SERVER CERT
    openssl ca -batch -config template.server.cnf \
        -extensions server_cert \
        -days 100 -notext -md sha256 \
        -in ${OUT_PATH}/${SERVER_NAME}.csr.pem \
        -out ${OUT_PATH}/${SERVER_NAME}.cert.pem
done
