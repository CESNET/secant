#!/usr/bin/env bash

IP=$1
FOLDER_PATH=$2

BASE=$(dirname $0)

[ -n "$FOLDER_PATH" ] || FOLDER_PATH=/tmp

if ! nmap -oX - -T 4 -n $IP > $FOLDER_PATH/nmap.xml; then
    exit 1
fi

echo OK
${BASE}/format_body.py < $FOLDER_PATH/nmap.xml
