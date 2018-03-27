#!/usr/bin/env bash
# $1 : ip address
# $2 : template id for logging
# $3 : functions.sh path

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

if ! nmap -oX - $IP > $FOLDER_PATH/nmap_output.xml; then
    exit 1
fi

echo OK
./format_body.py < $FOLDER_PATH/nmap_output.xml
