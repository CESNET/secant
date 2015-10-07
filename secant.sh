#!/usr/bin/env bash

waitall() {
  local errors=0
  while :; do
    for pid in "$@"; do
      shift
      if kill -0 "$pid" 2>/dev/null; then
        set -- "$@" "$pid"
      elif wait "$pid"; then
        debug "$pid exited with zero exit status."
      else
        debug "$pid exited with non-zero exit status."
        ((++errors))
      fi
    done
    (("$#" > 0)) || break
   done
 }

debug() { echo "[DEBUG] $*" >&2; }

TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed -n '14,18p')) # GEt first 5 templates ids

for TEMPLATE_ID in "${TEMPLATES[@]}"
do
    if [[ $TEMPLATE_ID =~ ^[0-9]+$ ]] ; then
        ./analyse_template.sh $TEMPLATE_ID &
        pids="$pids $!"
    fi
done

waitall $pids
echo "[INFO] Successfully completed!"