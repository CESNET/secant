#!/usr/bin/env bash
# $1 : ip address
# $2 : template id for logging
# $3 : functions.sh path

IP=$1
VM_ID=$2
TEMPLATE_IDENTIFIER=$3
FOLDER_PATH=$4
SHOULD_SECANT_SKIP_THIS_TEST=${5-false}

source ${SECANT_CONFIG:-/etc/secant/secant.conf}

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

if $SHOULD_SECANT_SKIP_THIS_TEST;
then
  python reporter.py $TEMPLATE_IDENTIFIER "SKIP"
  logging $TEMPLATE_IDENTIFIER "Skip NMAP_TEST." "DEBUG"
else
  if ! nmap -oX - $IP > $FOLDER_PATH/nmap_output.xml; then
    python reporter.py $TEMPLATE_IDENTIFIER "FAIL"
    logging $TEMPLATE_IDENTIFIER "NMAP_TEST failed due to error in nmap command!" "ERROR" "FAIL"
  fi
  cat $FOLDER_PATH/nmap_output.xml | python reporter.py $TEMPLATE_IDENTIFIER
  if [ "$?" -eq "1" ];
  then
    python reporter.py $TEMPLATE_IDENTIFIER "FAIL"
    logging $TEMPLATE_IDENTIFIER "NMAP_TEST failed, error appeared in reporter." "ERROR"
  fi
fi
