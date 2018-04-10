#!/bin/bash

VM_IP=$1
FOLDER_PATH=$2
TEMPLATE_IDENTIFIER=$3

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

remote_exec "$VM_IP" "$LOGIN_AS_USER" "perl - --site=SECANT" "$PAKITI_CLIENT" "$FOLDER_PATH/pakiti_test-pkgs.txt" 2>$FOLDER_PATH/pakiti.stderr
if [ $? -ne 0 ]; then
    # TODO: !!! check the stderr handling
    echo "Pakiti client failed to get a list of installed packages from the VM"
    cat $FOLDER_PATH/pakiti.stderr
    exit 1
fi

$PAKITI_CLIENT --url "$PAKITI_URL" --mode=store-and-report --host "$TEMPLATE_IDENTIFIER" --input $FOLDER_PATH/pakiti_test-pkgs.txt > $FOLDER_PATH/pakiti_test-result.txt 2>$FOLDER_PATH/pakiti_test-result.stderr
if [ $? -ne 0 ]; then
    echo "Pakiti test failed while sending data to the Pakiti server"
    cat $FOLDER_PATH/pakiti_test-result.stderr
    exit 1
fi

result=$(head -n 1 $FOLDER_PATH/pakiti_test-result.txt)
if [ "$result" = "OK" ]; then
    echo OK
    echo "No tagged vulnerabilities found by Pakiti"
    exit 0
fi

echo FAIL
echo "Pakiti detected vulnerable packages"
tail -n +2 $FOLDER_PATH/pakiti_test-result.txt
