#!/usr/bin/env bash
TEMPLATE_ID=$1
query='//DISK/IMAGE/text()'
images=()
while IFS= read -r entry; do
    images+=( "$entry" )
done < <(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "$query" -n)
oneimage show ${images[0]}  -x | xmlstarlet sel -t -v "//VMCATCHER_EVENT_AD_MPURI/text()" -n