#!/usr/bin/env bash

CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
source ${CONFIG_DIR}/secant.conf
source ${CONFIG_DIR}/cloud.conf

export ONE_XMLRPC=$ONE_XMLRPC

oneuser login "$SECANT_USER" --cert "$CERT_PATH" --key "$KEY_PATH" --x509 --force --time $((24*60*60))
