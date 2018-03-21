#!/bin/bash

TEMPLATE_ID=$1
TEMPLATE_IDENTIFIER=$2
BASE_MPURI=$3
FOLDER_PATH=$4

source ../include/functions.sh

# Basic configuration
EXTERNAL_TESTS_FOLDER_PATH=/opt/secant/external_tests
INTERNAL_TESTS_FOLDER_PATH=/opt/secant/internal_tests
# Make sure the environment is exposed to the tests
export DEBUG=true

analyse_template "$TEMPLATE_ID" "$TEMPLATE_IDENTIFIER" "$BASE_MPURI" "$FOLDER_PATH"
