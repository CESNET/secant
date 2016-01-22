#!/usr/bin/env bash

source secant.conf
source include/functions.sh

declare -A temp_id_with_pid

waitall() {
  local errors=0
  while :; do
    for pid in "$@"; do
      shift
      if kill -0 "$pid" 2>/dev/null; then
        set -- "$@" "$pid"
      elif wait "$pid"; then
        logging "[${temp_id_with_pid[${pid}]}] INFO: Analysis completed."
      else
        logging "[${temp_id_with_pid[${pid}]}] ERROR: Analysis failed."
        ((++errors))
      fi
    done

    (("$#" > 0)) || break
   done
 }

print_ascii_art
export ONE_XMLRPC=$ONE_XMLRPC
oneuser login secant --cert /root/.secant/secant-cert.pem --key /root/.secant/secant-key.pem --x509 --force

TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed -n '13,13p')) # Get first 5 templates ids
#TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed '1d'))
query='//NIFTY_ID' # attribute which determines that template should be analyzed
for TEMPLATE_ID in "${TEMPLATES[@]}"
do
    onetemplate show $TEMPLATE_ID -x > /tmp/tmp_"$TEMPLATE_ID".xml
    NIFTY_ID=$(xmlstarlet sel -t -v "$query" -n /tmp/tmp_"$TEMPLATE_ID".xml)
    if [ -z "$NIFTY_ID" ]; then # n - for not empty
        TEMPLATES_FOR_ANALYSIS+=($TEMPLATE_ID)
    fi
    rm -f /tmp/tmp_"$TEMPLATE_ID".xml
done

for TEMPLATE_ID in "${TEMPLATES_FOR_ANALYSIS[@]}"
do
    if [[ $TEMPLATE_ID =~ ^[0-9]+$ ]] ; then
        ./analyse_template.sh $TEMPLATE_ID &
        template_pid=$!
        pids="$pids $template_pid"
        temp_id_with_pid+=( [$template_pid]=$TEMPLATE_ID)
    fi
done

waitall $pids