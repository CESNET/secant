#!/usr/bin/env bash

CURRENT_DIRECTORY=${PWD##*/}
if [[ "$CURRENT_DIRECTORY" != "secant" ]] ; then
	echo `date +"%Y-%d-%m %H:%M:%S"` "[SECANT] ERROR: Please run Secant from the secant directory."
	exit 0
fi
source conf/secant.conf
source include/functions.sh

declare -A temp_id_with_pid

clean_if_analysis_failed() {
    VM_IDS=($(onevm list | awk '{ print $1 }' | sed '1d'))
    for VM_ID in "${VM_IDS[@]}"
    do
        query='//NIFTY_APPLIANCE_ID'
        NIFTY_ID=$(onevm show $VM_ID -x | xmlstarlet sel -t -v "$query")
        if [ -n "$NIFTY_ID" ]; then # n - for not empty
            if [[ $NIFTY_ID == $1 ]]; then
                onevm shutdown $VM_ID --hard
            fi
        fi
    done
}

delete_template_and_images(){
	# Get Template Images
	query='//DISK/IMAGE/text()'
	images=()
	while IFS= read -r entry; do
	  images+=( "$entry" )
	done < <(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "$query" -n)

	for image_name in "${images[@]}"
	do
	    DELETE_IMAGE_RESULT=$(oneimage delete "$image_name")
	    if [[ ! -n  $DELETE_IMAGE_RESULT ]]
	    then
	        logging $TEMPLATE_IDENTIFIER "Image: $image_name successfully deleted." "DEBUG"
	    else
            CHECK_FOR_IMAGE_MANAGE_ERROR=$(echo $DELETE_IMAGE_RESULT | grep -o "Not authorized to perform MANAGE IMAGE \[.[0-9]*\]")
            if [[ -n $CHECK_FOR_IMAGE_MANAGE_ERROR ]]
            then
                logging $TEMPLATE_IDENTIFIER "Secant user is not authorized to delete image: $(echo $CHECK_FOR_IMAGE_MANAGE_ERROR | grep -o '[0-9]*')." "ERROR"
            fi
        fi
	done

    DELETE_TEMPLATE_RESULT=$(onetemplate delete $TEMPLATE_ID)
    if [[ ! -n  $DELETE_TEMPLATE_RESULT ]]
	then
	    logging $TEMPLATE_IDENTIFIER "Template: $TEMPLATE_ID successfully deleted." "DEBUG"
    else
        CHECK_FOR_TEMPLATE_MANAGE_ERROR=$(echo $DELETE_TEMPLATE_RESULT | grep -o "Not authorized to perform MANAGE TEMPLATE \[.[0-9]*\]")
        if [[ -n $CHECK_FOR_TEMPLATE_MANAGE_ERROR ]]
        then
            logging $TEMPLATE_IDENTIFIER "Secant user is not authorized to delete template: $(echo $CHECK_FOR_TEMPLATE_MANAGE_ERROR | grep -o '[0-9]*')." "ERROR"
        fi
    fi
}

waitall() {
  local errors=0
  while :; do
    for pid in "$@"; do
      shift
      if kill -0 "$pid" 2>/dev/null; then
        set -- "$@" "$pid"
      elif wait "$pid"; then
        logging ${temp_id_with_pid[${pid}]} "Analysis completed successfully." "INFO"
        delete_template_and_images $TEMPLATE_ID
      else
        clean_if_analysis_failed ${temp_id_with_pid[${pid}]}
        logging ${temp_id_with_pid[${pid}]} "Analysis finished with errors." "ERROR"
        delete_template_and_images $TEMPLATE_ID
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

TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed -n '2,2p')) # Get first 5 templates ids
#TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed '1d'))

query='//NIFTY_ID' # attribute which determines that template should be analyzed
for TEMPLATE_ID in "${TEMPLATES[@]}"
do
    #NIFTY_ID=$(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "$query")
    #if [ -n "$NIFTY_ID" ]; then # n - for not empty
        TEMPLATES_FOR_ANALYSIS+=($TEMPLATE_ID)
    #fi
done

#TEMPLATE_IDENTIFIER=$(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "//NIFTY_APPLIANCE_ID")
TEMPLATE_IDENTIFIER=$TEMPLATE_ID
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
            logging $TEMPLATE_IDENTIFIER "Analysis started." "INFO"
            template_pid=$!
            pids="$pids $template_pid"
            temp_id_with_pid+=( [$template_pid]=$TEMPLATE_IDENTIFIER)
        fi
    done
fi

waitall $pids