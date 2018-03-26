#!/usr/bin/env bash

CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
source ${CONFIG_DIR}/secant.conf
export ONE_XMLRPC=$ONE_XMLRPC

ret=$(oneuser login secant --cert "$CERT_PATH" --key "$KEY_PATH" --x509 --force 2>&1)
if [ $? -ne 0 ]; then
    echo $ret
    exit 1
fi
cp ~/.one/one_auth ~cloudkeeper-one/.one && (chown cloudkeeper-one ~cloudkeeper-one/.one/one_auth; chmod 0600 ~cloudkeeper-one/.one/one_auth)
#systemctl restart cloudkeeper-one
/etc/init.d/cloudkeeper-one restart > /dev/null
