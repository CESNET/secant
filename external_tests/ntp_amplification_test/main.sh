#!/usr/bin/env bash

IP=$1
VM_ID=$2
TEMPLATE_IDENTIFIER=$3
FOLDER_PATH=$4

ntpdc -n -c monlist "$IP" > $FOLDER_PATH/ntpdc.stdout 2>$FOLDER_PATH/ntpdc.stderr
if [ $? -ne 0 ]; then
    cat $FOLDER_PATH/ntpdc.stderr
    exit 1
fi

# we should better check with nmap (or consult its previous run)
grep -q 'ntpdc: read: Connection refused' $FOLDER_PATH/ntpdc.stderr
if [ $? -eq 0 ]; then
   echo OK
   echo "The ntpd port isn't open"
   exit 0
fi

./generate_report.py < $FOLDER_PATH/ntpdc.stdout
