#!/bin/bash

if [ ! "$#" -eq 3 ] ; then
  echo "3 argument required, $# provided!"
  exit 1
fi

if  [ ! -d  $2 ]  ; then
  echo "Directory $dir does not exist!"
  exit 1
fi

CURRENT_DIRECTORY=${PWD##*/}
if [[ "$CURRENT_DIRECTORY" == "lib" ]] ; then
    source ../include/functions.sh
else
    if [[ "$CURRENT_DIRECTORY" == "secant" ]] ; then
        source include/functions.sh
    else
        source ../include/functions.sh
    fi
fi

TEMPLATE_ID=$1
TEMPLATE_IDENTIFIER=$2
REPORT_FOLDER=$3
USER_DATA_FILE=$REPORT_FOLDER/user_data.yaml
CONTEXT_FILE=$REPORT_FOLDER/ctx."$TEMPLATE_IDENTIFIER".txt
#MPURI=$(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "//VMCATCHER_EVENT_AD_MPURI/text()" -n)
MPURI="https://appdb.egi.eu/store/vm/image/5429adc6-61bc-413d-b465-e8f655617ad4:5764/" # For test purposes
wget "$MPURI"xml -O $REPORT_FOLDER/"$TEMPLATE_IDENTIFIER".xml > /dev/null 2>&1
CONTEXT_SCRIPT_URL=$(xmlstarlet sel -t  -v "//virtualization:contextscript/url" -n $REPORT_FOLDER/"$TEMPLATE_IDENTIFIER".xml)
wget $CONTEXT_SCRIPT_URL -O $USER_DATA_FILE > /dev/null 2>&1
if [[ -z "$CONTEXT_SCRIPT_URL" ]]; then
  logging $TEMPLATE_IDENTIFIER "Could not obtain url of context script." "ERROR"
  exit 1
fi

if [ ! -f "$USER_DATA_FILE" ] ; then
  logging $TEMPLATE_IDENTIFIER "File $USER_DATA_FILE not found." "ERROR"
  exit 1
fi

cat >$CONTEXT_FILE <<"EOF"
CONTEXT=[
  EMAIL="$USER[EMAIL]",
  PUBLIC_IP="$NIC[IP]",
  SSH_KEY="$USER[SSH_KEY]",
  TARGET="vdb",
  TOKEN="YES",
  VM_GID="$GID",
  VM_GNAME="$GNAME",
  VM_ID="$VMID",
  VM_UID="$UID",
  VM_UNAME="$UNAME",
  USERDATA_ENCODING="base64",
EOF
echo >>$CONTEXT_FILE -n '  USER_DATA="'
base64 >>$CONTEXT_FILE -w 0 $USER_DATA_FILE
cat >>$CONTEXT_FILE <<EOF
"
]
EOF
onetemplate instantiate -v $TEMPLATE_ID $CONTEXT_FILE