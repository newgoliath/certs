#!/bin/bash

# create a Certificate Authority in $PWD

GUID=${GUID:-'rdu1'}
DIR="${DIR:-`pwd`}"
echo "Working directory: ${DIR}"
cd ${DIR}

CA_DIR=${DIR}/ca
cd ${CA_DIR}

# create the second intermediate cert to be used in OpenShift
INTER_DIR=${CA_DIR}/intermediate
mkdir ${INTER_DIR}
cd ${INTER_DIR}

SERVER_NAME="loadbalancer.${GUID}.example.opentlc.com"

echo --- creating the SERVER KEY
openssl genrsa -out ${INTER_DIR}/private/${SERVER_NAME}.key.pem 2048

echo --- creating the SERVER CSR
# server key and certificate
openssl req -nodes -new -sha256 \
      -config ${DIR}/${SERVER_NAME}.cnf -extensions server_cert \
      -key ${INTER_DIR}/private/${SERVER_NAME}.key.pem \
      -out ${INTER_DIR}/csr/${SERVER_NAME}.csr.pem

echo --- creating the SERVER CERT
openssl ca -config ${DIR}/${SERVER_NAME}.cnf -extensions server_cert \
	-days 100 -notext -md sha256 \
	-in ${INTER_DIR}/csr/${SERVER_NAME}.csr.pem \
	-out ${INTER_DIR}/certs/${SERVER_NAME}.cert.pem

echo --- verify the SERVER CERT
openssl x509 -noout -text \
	-in ${INTER_DIR}/certs/${SERVER_NAME}.cert.pem

