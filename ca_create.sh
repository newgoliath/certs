#!/bin/bash

# create a Certificate Authority in $PWD

GUID=${GUID-'rdu1'}
DIR="${DIR:-`pwd`}"
echo "Working directory: ${DIR}"
cd ${DIR}

# make the basics
echo --- preparing environment
CA_DIR=${DIR}/ca
mkdir -p ${CA_DIR}/certs ${CA_DIR}/crl ${CA_DIR}/newcerts ${CA_DIR}/private
chmod 700 ${CA_DIR}/private
touch ${CA_DIR}/index.txt
echo 1000 > ${CA_DIR}/serial

# create the root key
echo --- creating the ROOT CERT
openssl genrsa -out ${CA_DIR}/private/ca.key.pem 4096 
#openssl genrsa -aes256 -passout pass:password1 -out ${CA_DIR}/private/ca.key.pem 4096 
#chmod 400 private/ca.key.pem

echo --- creating the ROOT KEY
# create the root cert
openssl req -config "${DIR}/root_ca_openssl.cnf" \
      -key ${CA_DIR}/private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out ${CA_DIR}/certs/ca.cert.pem 
      #-passin pass:password1 \
      #-passout pass:password1 \
      #-subj '/CN=www.mydom.com/O=My Company Name LTD./C=US'

# create the intermediate cert to be used in OpenShift
INTER_DIR=${CA_DIR}/intermediate
mkdir ${INTER_DIR}
mkdir ${INTER_DIR}/certs ${INTER_DIR}/crl ${INTER_DIR}/csr ${INTER_DIR}/newcerts ${INTER_DIR}/private
chmod 700 ${INTER_DIR}/private
touch ${INTER_DIR}/index.txt
echo 1000 > ${INTER_DIR}/crlnumber
echo 1000 > ${INTER_DIR}/serial

# create intermediate key
echo --- creating the intermediate KEY
#openssl genrsa \#h-aes256 \
openssl genrsa -out ${INTER_DIR}/private/intermediate.key.pem 4096
#      -passout pass:intermed_key \

# create intermediate cert

# create cert signing request
echo --- creating the intermediate CSR
openssl req -config ${DIR}/intermediate_ca_openssl.cnf -new -sha256 \
      -key ${INTER_DIR}/private/intermediate.key.pem \
      -out ${INTER_DIR}/csr/intermediate.csr.pem
#      -passin pass:intermed_key \
#      -passout pass:intermed_csr \
      #-subj '/CN=www.mydom.com/O=My Company Name LTD./C=US' \

echo --- creating the intermediate CERT
openssl ca -config ${DIR}/root_ca_openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 -batch \
      -in ${INTER_DIR}/csr/intermediate.csr.pem \
      -out ${INTER_DIR}/certs/intermediate.cert.pem
      #-passin pass:intermed_csr \
      #-passin pass:password1 \


# verify the chain
echo --- verifying the Intermediate cert
openssl verify -CAfile ${CA_DIR}/certs/ca.cert.pem \
      ${INTER_DIR}/certs/intermediate.cert.pem


