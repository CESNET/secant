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
  logging $TEMPLATE_IDENTIFIER "Skip NTP_AMPLIFICATION_TEST." "DEBUG"
else
  ntpdc -n -c monlist "$IP" &> $FOLDER_PATH/ntp_output.txt
  if [ "$?" -eq "1" ]; then
    python reporter.py $TEMPLATE_IDENTIFIER "FAIL"
    logging $TEMPLATE_IDENTIFIER "NTP_AMPLIFICATION_TEST failed due to error in  command!" "ERROR" "FAIL"
  else
    cat $FOLDER_PATH/ntp_output.txt | python reporter.py $TEMPLATE_IDENTIFIER
    if [ "$?" -eq "1" ];
    then
        python reporter.py $TEMPLATE_IDENTIFIER "FAIL"
        logging $TEMPLATE_IDENTIFIER "NTP_AMPLIFICATION_TEST failed, error appeared in reporter." "ERROR"
    fi
  fi
fi
