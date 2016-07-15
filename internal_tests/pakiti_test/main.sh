#!/bin/bash

VM_IP=$1
VM_ID=$2 # VM ID in OpenNebul
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

# Remotely run Pakiti client
ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$VM_IP 'bash -s' < pakiti2-client-meta.sh > $FOLDER_PATH/pakiti_test-pkgs.txt

# Check if pakiti-pkg file is empty
for i in {1..5}; do
if [ ! -s $FOLDER_PATH/pakiti_test-pkgs.txt ]
    then
            logging $TEMPLATE_IDENTIFIER "Pakiti report file is empty, try again!" "DEBUG"
            sleep 10
            ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$VM_IP 'bash -s' < pakiti2-client-meta.sh > $FOLDER_PATH/pakiti_test-pkgs.txt
    fi
done

if [ ! -s $FOLDER_PATH/pakiti_test-pkgs.txt ]
then
        logging $TEMPLATE_IDENTIFIER "Pakiti report file is empty!" "ERROR"
        logging $TEMPLATE_IDENTIFIER "PAKITI_TEST failed!" "ERROR"
        exit 1
fi

sed -i -e 's/host="[^"]\+"/host="'$TEMPLATE_IDENTIFIER'"/g' $FOLDER_PATH/pakiti_test-pkgs.txt
./pakiti2-client-meta-proxy.sh < $FOLDER_PATH/pakiti_test-pkgs.txt > $FOLDER_PATH/pakiti_test-result.txt 2>&1

if [ "$?" -eq "0" ];
then
    cat $FOLDER_PATH/pakiti_test-result.txt | python reporter.py $TEMPLATE_IDENTIFIER
else
    logging $TEMPLATE_IDENTIFIER "Occured while sending data to the Pakiti server!" "ERROR"
fi
