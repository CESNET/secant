#!/usr/bin/env bash

declare -A temp_id_with_pid

waitall() {
  local errors=0
  while :; do
    for pid in "$@"; do
      shift
      if kill -0 "$pid" 2>/dev/null; then
        set -- "$@" "$pid"
      elif wait "$pid"; then
        debug "[${temp_id_with_pid[${pid}]}] INFO: Analysis completed."
      else
        debug "[${temp_id_with_pid[${pid}]}] ERROR: Analysis failed."
        ((++errors))
      fi
    done

    (("$#" > 0)) || break
   done
 }

debug() { echo `date +"%Y-%d-%m %H:%M:%S"` "$*" >&2; }

TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed -n '12,14p')) # GEt first 5 templates ids

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