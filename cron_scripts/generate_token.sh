#!/usr/bin/env bash

CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
source ${CONFIG_DIR}/secant.conf
export ONE_XMLRPC=$ONE_XMLRPC
oneuser login secant --cert "$CERT_PATH" --key "$KEY_PATH" --x509 --force
logger -s "Token generated!"
