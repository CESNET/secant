#!/bin/bash

TEMPLATE_ID=$1
TEMPLATE_IDENTIFIER=$2
BASE_MPURI=$3
FOLDER_PATH=$4

SECANT_PATH=$(dirname $0)/..
source $SECANT_PATH/include/functions.sh

# Make sure the environment is exposed to the tests
export DEBUG=true

analyse_template "$TEMPLATE_ID" "$TEMPLATE_IDENTIFIER" "$BASE_MPURI" "$FOLDER_PATH"
