#!/usr/bin/env bash

BASE=$(dirname "$0")
source $BASE/../include/cloud_on.sh

TEMPLATES=($(cloud_get_template_ids))
if [ $? -ne 0 ]; then
    exit 1
fi

for TEMPLATE_ID in "${TEMPLATES[@]}"
do
    MESSAGE_ID=$(cloud_template_query "$TEMPLATE_ID" "//MESSAGEID")
    if [ $? -eq 0 ]; then
        if [ "$MESSAGE_ID" = "$1" ]; then
            exit 0
        fi
    fi
done

exit 1
