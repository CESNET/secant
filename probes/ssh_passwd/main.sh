#!/usr/bin/env bash

IP=$1
FOLDER_PATH=$2

CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
source ${CONFIG_DIR}/probes.conf

hydra -L $SECANT_PROBE_HYDRA/ser.list -P $SECANT_PROBE_HYDRA/passwd.list -t 8 $IP ssh > $FOLDER_PATH/hydra.stdout 2>$FOLDER_PATH/ssh_passwd.stderr
grep -q "0 valid" $FOLDER_PATH/hydra.stdout
if [ $? -eq 0 ]; then
    echo OK
    echo Password was not cracked
    echo Dictionary attack finished successfully with 0 valid passwords found.
    exit 0
fi

grep -q "1 valid" $FOLDER_PATH/hydra.stdout
if [ $? -eq 0 ]; then
    echo ERROR
    echo Password was cracked!
    echo Dictionary attack finished successfully and found valid password.
    exit 0
fi

>&2 echo Hydra failed to run correctly
exit 1
