#!/usr/bin/env bash
# $1 : ip address
# $2 : template id for logging
# $3 : functions.sh path

IP=$1
TEMPLATE_IDENTIFIER=$2
DEFAULT_FUNCTIONS_FILE_PATH=../../include/functions.sh
FUNCTIONS_FILE_PATH=${3-$DEFAULT_FUNCTIONS_FILE_PATH}
source "$FUNCTIONS_FILE_PATH" ../../conf/secant.conf

if ! nmap -oX - $IP | python reporter.py 2> /tmp/stderr.txt; then
  EXCEPTION=$(cat /tmp/stderr.txt | egrep 'IOError:')
  logging "[$TEMPLATE_IDENTIFIER] ERROR: $EXCEPTION"
  rm /tmp/stderr.txt
fi