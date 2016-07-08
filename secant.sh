#!/usr/bin/env bash

source conf/secant.conf
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
        logging ${temp_id_with_pid[${pid}]} "Analysis completed." "INFO"
      else
        logging ${temp_id_with_pid[${pid}]} "Analysis failed." "ERROR"
        ((++errors))
      fi
    done

    (("$#" > 0)) || break
   done
 }

print_ascii_art
echo `date +"%Y-%d-%m %H:%M:%S"` "[SECANT] INFO: Start Secant."
echo `date +"%Y-%d-%m %H:%M:%S"` "[SECANT] INFO: Debug information: $log_file."

export ONE_XMLRPC=$ONE_XMLRPC
oneuser login secant --cert $CERT_PATH --key $KEY_PATH --x509 --force >/dev/null 2>&1

#TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed -n '13,13p')) # Get first 5 templates ids
TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed '1d'))

query='//NIFTY_ID' # attribute which determines that template should be analyzed
for TEMPLATE_ID in "${TEMPLATES[@]}"
do
    NIFTY_ID=$(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "$query")
    if [ -n "$NIFTY_ID" ]; then # n - for not empty
        TEMPLATES_FOR_ANALYSIS+=($TEMPLATE_ID)
    fi
done

TEMPLATE_IDENTIFIER=$(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "//NIFTY_APPLIANCE_ID")
#TEMPLATE_IDENTIFIER=$TEMPLATE_ID
if [ ${#TEMPLATES_FOR_ANALYSIS[@]} -eq 0 ]; then
    logging "SECANT" "No templates for analysis." "INFO"
else
    for TEMPLATE_ID in "${TEMPLATES_FOR_ANALYSIS[@]}"
    do
        if [[ $TEMPLATE_ID =~ ^[0-9]+$ ]] ; then

            # Check if directory for reports already exist, if not create
            if [[ ! -e $reports_directory ]]; then
                mkdir $reports_directory
            fi

            ./lib/analyse_template.sh $TEMPLATE_ID $TEMPLATE_IDENTIFIER &
            template_pid=$!
            pids="$pids $template_pid"
            temp_id_with_pid+=( [$template_pid]=$TEMPLATE_IDENTIFIER)
        fi
    done
fi

waitall $pids