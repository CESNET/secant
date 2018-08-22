#!/usr/bin/env bash

# The script must be run as root.

# TODO: Perhaps we should use different creds for secant and cloudkeeper-one (?)

CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
source ${CONFIG_DIR}/secant.conf

SECANT_PATH=$(dirname $0)/..
ret=$(sudo -u "$SECANT_USER" $SECANT_PATH/tools/get_token.sh 2>&1)
if [ $? -ne 0 ]; then
    echo $ret
    exit 1
fi

SRC_AUTH=$(eval echo "~${SECANT_USER}/.one/one_auth")
umask 177
cp $SRC_AUTH ~cloudkeeper-one/.one || exit 1
chown cloudkeeper-one ~cloudkeeper-one/.one/one_auth || exit 1

#systemctl restart cloudkeeper-one
/etc/init.d/cloudkeeper-one restart > /dev/null

/etc/init.d/cloudkeeper-one-secant restart > /dev/null
