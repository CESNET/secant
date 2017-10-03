#!/usr/bin/env bash

source ${SECANT_CONFIG:-/etc/secant/secant.conf}
export ONE_XMLRPC=$ONE_XMLRPC
oneuser login secant --cert $CERT_PATH --key $CERT_KEY --x509 --force
logger -s "Token generated!"
