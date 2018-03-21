#!/bin/bash

VM_IP=$1
VM_ID=$2 # VM ID in OpenNebul
TEMPLATE_IDENTIFIER=$3
FOLDER_PATH=$4
LOGIN_AS_USER=$5
SHOULD_SECANT_SKIP_THIS_TEST=${6-false}

PAKITI_CLIENT="/opt/pakiti-client/pakiti-client"
PAKITI_URL=https://pakiti.cesnet.cz/egi/feed/

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

if [[ $# -eq 0 ]] ; then
    echo 'No input arguments'
    exit 1
fi

if $SHOULD_SECANT_SKIP_THIS_TEST;
then
    printf "SKIP" | python reporter.py $TEMPLATE_IDENTIFIER
    logging $TEMPLATE_IDENTIFIER "Skip PAKITI_TEST." "DEBUG"
    exit 0
fi

remote_exec "$VM_IP" "$LOGIN_AS_USER" "perl - --site=SECANT" "$PAKITI_CLIENT" "$FOLDER_PATH/pakiti_test-pkgs.txt"
if [ $? -ne 0 ]; then
    printf "FAIL" | python reporter.py $TEMPLATE_IDENTIFIER
    logging $TEMPLATE_IDENTIFIER "PAKITI_TEST failed to get a list of installed packages from the VM" "ERROR"
    exit 1
fi

$PAKITI_CLIENT --url "$PAKITI_URL" --mode=store-and-report --host "$TEMPLATE_IDENTIFIER" --input $FOLDER_PATH/pakiti_test-pkgs.txt > $FOLDER_PATH/pakiti_test-result.txt
if [ $? -ne 0 ]; then
    printf "FAIL" | python reporter.py $TEMPLATE_IDENTIFIER
    logging $TEMPLATE_IDENTIFIER "PAKITI_TEST failed while sending data to the Pakiti server." "ERROR"
    exit 1
fi

cat $FOLDER_PATH/pakiti_test-result.txt | python reporter.py $TEMPLATE_IDENTIFIER

exit 0
