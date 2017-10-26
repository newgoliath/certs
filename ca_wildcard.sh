#!/bin/bash

GUID=${GUID-'rdu1'}
DIR="${DIR:-`pwd`}"
echo "Working directory: ${DIR}"
cd ${DIR}

CA_DIR=${DIR}/ca
cd ${CA_DIR}

# create the second intermediate cert to be used in OpenShift
INTER_DIR=${CA_DIR}/intermediate
mkdir ${INTER_DIR}
cd ${INTER_DIR}

WILDCARD_NAME="wildcard.apps.${GUID}.example.opentlc.com"

echo --- creating the WILDCARD KEY
openssl genrsa -out ${INTER_DIR}/private/${WILDCARD_NAME}.key.pem 2048

echo --- creating the WILDCARD CSR
# server key and certificate
openssl req -nodes -new -sha256 \
      -config ${DIR}/${WILDCARD_NAME}.cnf -extensions server_cert \
      -key ${INTER_DIR}/private/${WILDCARD_NAME}.key.pem \
      -out ${INTER_DIR}/csr/${WILDCARD_NAME}.csr.pem

echo --- creating the WILDCARD CERT
openssl ca -config ${DIR}/${WILDCARD_NAME}.cnf -extensions server_cert \
	-days 100 -notext -md sha256 \
	-in ${INTER_DIR}/csr/${WILDCARD_NAME}.csr.pem \
	-out ${INTER_DIR}/certs/${WILDCARD_NAME}.cert.pem

echo --- verify the WILDCARD CERT
openssl x509 -noout -text \
	-in ${INTER_DIR}/certs/${WILDCARD_NAME}.cert.pem
