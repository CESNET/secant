#!/bin/bash

IPADDRESSES=$1
TEMPLATE_IDENTIFIER=$2
VM_ID=$3
FOLDER_TO_SAVE_REPORTS=$4

source $(dirname $0)/../conf/secant.conf
SECANT_PATH=$(dirname $0)/..
source $SECANT_PATH/include/functions.sh

# Make sure the environment is exposed to the tests
export DEBUG=true

IFS=',' read -r -a ipAddresses <<< "$IPADDRESSES"

analyse_machine "$TEMPLATE_IDENTIFIER" "$VM_ID" "$FOLDER_TO_SAVE_REPORTS" "${ipAddresses[@]}"
