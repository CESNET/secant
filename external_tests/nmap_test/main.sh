#!/usr/bin/env bash

IP=$1
FOLDER_PATH=$2

[ -n "$FOLDER_PATH" ] || FOLDER_PATH=/tmp

if ! nmap -oX - -T 4 -n $IP > $FOLDER_PATH/nmap_output.xml; then
    exit 1
fi

echo OK
./format_body.py < $FOLDER_PATH/nmap_output.xml
