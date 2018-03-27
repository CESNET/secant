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

ntpdc -n -c monlist "$IP" > $FOLDER_PATH/ntp_output.txt
if [ $? -ne 0 ]; then
    # we should better check with nmap (or consult its previous run)
    grep -q 'ntpdc: read: Connection refused' $FOLDER_PATH/ntp_stderr
    if [ $? -eq 0 ]; then
       echo OK
       echo "The ntpd port isn't open"
       exit 0
    fi
    exit 1
fi

./generate_report.py < $FOLDER_PATH/ntp_output.txt
