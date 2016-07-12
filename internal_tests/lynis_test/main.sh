#!/usr/bin/env bash
VM_IP=$1
VM_ID=$2 # VM ID in OpenNebula
TEMPLATE_IDENTIFIER=$3
FOLDER_PATH=$4

CURRENT_DIRECTORY=${PWD##*/}
if [[ "$CURRENT_DIRECTORY" == "lib" ]] ; then
    source ../conf/secant.conf
    source ../include/functions.sh
else
    if [[ "$CURRENT_DIRECTORY" == "secant" ]] ; then
        source conf/secant.conf
        source include/functions.sh
    else
        source ../../conf/secant.conf
        source ../../include/functions.sh
    fi
fi

scp -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -r $lynis_directory/lynis/ root@$VM_IP:/tmp > /tmp/scp.log 2>&1

if [ "$?" -eq "0" ];
then
    if ! ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$VM_IP 'bash -s' < lynis-client.sh > $FOLDER_PATH/lynis_test.txt; then
        logging $TEMPLATE_IDENTIFIER] "During Lynis testing!" "ERROR"
    fi
    cat $FOLDER_PATH/lynis_test.txt | python reporter.py $TEMPLATE_IDENTIFIER
    if [ "$?" -eq "1" ];
    then
        logging $TEMPLATE_IDENTIFIER "Lynis test failed!" "ERROR"
    fi
else
    logging $TEMPLATE_IDENTIFIER "Scp command failed!" "ERROR"
fi
rm -f /tmp/scp.log