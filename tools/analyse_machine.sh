#!/bin/bash

usage() {
    echo "Script run tests on given machines. More information about tests is in README."
    echo "Script takes exactly 2 arguments:"
    printf "\t1. IP addresses separated by commas.\n"
    printf "\t2. Folder to save report.\n"
}

if [[ $@ == "--help" ||  $@ == "-h" ]]; then 
    usage
    exit 0
fi

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

IPADDRESSES=$1
FOLDER_TO_SAVE_REPORTS=$2
TEMPLATE_IDENTIFIER=1
VM_ID=1

SECANT_PATH=$(dirname $0)/..
source $SECANT_PATH/include/functions.sh

# Make sure the environment is exposed to the tests
export DEBUG=true

IFS=',' read -r -a ipAddresses <<< "$IPADDRESSES"

analyse_machine "$TEMPLATE_IDENTIFIER" "$VM_ID" "$FOLDER_TO_SAVE_REPORTS" "${ipAddresses[@]}"
