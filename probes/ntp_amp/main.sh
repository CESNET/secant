#!/usr/bin/env bash

IP=$1
FOLDER_PATH=$2

BASE=$(dirname $0)

ntpdc -n -c monlist "$IP" > $FOLDER_PATH/ntpdc.stdout 2>$FOLDER_PATH/ntpdc.stderr
if [ $? -ne 0 ]; then
    cat $FOLDER_PATH/ntpdc.stderr
    exit 1
fi


${BASE}/generate_report.py < $FOLDER_PATH/ntpdc.stdout
