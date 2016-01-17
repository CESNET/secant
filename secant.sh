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


export ONE_XMLRPC=$ONE_XMLRPC
oneuser login secant --cert /root/.secant/secant-cert.pem --key /root/.secant/secant-key.pem --x509 --force

TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed -n '13,13p')) # GEt first 5 templates ids

for TEMPLATE_ID in "${TEMPLATES[@]}"
do
    if [[ $TEMPLATE_ID =~ ^[0-9]+$ ]] ; then
        ./analyse_template.sh $TEMPLATE_ID &
        template_pid=$!
        pids="$pids $template_pid"
        temp_id_with_pid+=( [$template_pid]=$TEMPLATE_ID)
    fi
done

waitall $pids