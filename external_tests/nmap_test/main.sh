#!/usr/bin/env bash
# $1 : ip address
# $2 : template id for logging
# $3 : functions.sh path

IP=$1
VM_ID=$2
TEMPLATE_IDENTIFIER=$3
DEFAULT_FUNCTIONS_FILE_PATH=../../include/functions.sh
FUNCTIONS_FILE_PATH=${5-$DEFAULT_FUNCTIONS_FILE_PATH}
source "$FUNCTIONS_FILE_PATH" ../../conf/secant.conf
FOLDER_PATH=$4

if ! nmap -oX - $IP > $FOLDER_PATH/nmap_output.xml; then
  logging $TEMPLATE_IDENTIFIER "During Nmap command appeared!" "ERROR"
fi

cat $FOLDER_PATH/nmap_output.xml | python reporter.py $TEMPLATE_IDENTIFIER
