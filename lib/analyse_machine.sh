#!/bin/bash

IPADDRESSES=$1
TEMPLATE_IDENTIFIER=$2
VM_ID=$3
FOLDER_TO_SAVE_REPORTS=$4

source ../include/functions.sh

# Basic configuration
EXTERNAL_TESTS_FOLDER_PATH=/opt/secant/external_tests
INTERNAL_TESTS_FOLDER_PATH=/opt/secant/internal_tests
# Make sure the environment is exposed to the tests
export DEBUG=true

IFS=',' read -r -a ipAddresses <<< "$IPADDRESSES"

analyse_machine "$TEMPLATE_IDENTIFIER" "$VM_ID" "$FOLDER_TO_SAVE_REPORTS" "${ipAddresses[@]}"
