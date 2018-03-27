#!/usr/bin/env bash

IP=$1
VM_ID=$2
TEMPLATE_IDENTIFIER=$3
FOLDER_PATH=$4

CURRENT_DIRECTORY=${PWD##*/}
if [[ "$CURRENT_DIRECTORY" == "lib" ]] ; then
    source ../include/functions.sh
else
    if [[ "$CURRENT_DIRECTORY" == "secant" ]] ; then
        source include/functions.sh
    else
        source ../../include/functions.sh
    fi
fi

SSH_PORT_STATUS=`nmap $IP -PN -p ssh | grep open`
if [ -z "$SSH_PORT_STATUS" ]; then
    echo OK
    echo "SSH port is not open"
    exit 0
fi

ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=none $IP &> $FOLDER_PATH/ssh_authentication_out
grep -q "Permission denied.*password" $FOLDER_PATH/ssh_authentication_out
if [ $? -eq 0 ]; then
    echo FAIL
    echo "SSH enables password-based authentication"
    exit 0
fi

echo OK
echo "SSH does not enable password-based authentication"
exit 0
