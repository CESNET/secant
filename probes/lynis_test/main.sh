#!/usr/bin/env bash

VM_IP=$1
FOLDER_PATH=$2

SHOULD_SECANT_SKIP_THIS_TEST=${6-false}
BASE=$(dirname "$0")
CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
source ${CONFIG_DIR}/probes.conf
source $BASE/../../include/functions.sh

if $SHOULD_SECANT_SKIP_THIS_TEST;
then
    echo "SKIPPED"
    echo "Lynis test is actually skipped"
    logging $TEMPLATE_IDENTIFIER "Skip LYNIS_TEST." "DEBUG"
else
    LOGIN_AS_USER=secant
    scp -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey -r "$SECANT_PROBE_LYNIS" "$LOGIN_AS_USER"@$VM_IP:/tmp > /tmp/scp.log 2>&1
    if [ "$?" -eq "0" ];
    then
        ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey "$LOGIN_AS_USER"@$VM_IP 'sudo bash -s' < ${BASE}/lynis-client.sh > $FOLDER_PATH/lynis_test.txt 2> /dev/null
        ret=$?
        if [ $ret -ne 0 ]; then
            ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey "$LOGIN_AS_USER"@$VM_IP 'bash -s' < ${BASE}/lynis-client.sh > $FOLDER_PATH/lynis_test.txt
            ret=$?
        fi
        if [ $ret -eq 0 ]; then
            echo "OK"
            echo "Logged in as user $LOGIN_AS_USER, and lynis test completed"
            cat $FOLDER_PATH/lynis_test.txt
        else
            logging $TEMPLATE_IDENTIFIER "During Lynis testing!" "ERROR"
            exit 1
        fi
    else
        echo "SKIPPED"
        echo "LYNIS_TEST skipped due to unsuccessful scp command!"
        logging $TEMPLATE_IDENTIFIER "LYNIS_TEST failed due to unsuccessful scp commmand!" "ERROR"
    fi
    rm -f /tmp/scp.log
fi
