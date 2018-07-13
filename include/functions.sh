#!/usr/bin/env bash
# $1 : secant conf file path

#SECANT_CONF_PATH=${1-$DEFAULT_SECANT_CONF_PATH}
#source "$SECANT_CONF_PATH"

SECANT_STATUS_OK="OK"
SECANT_STATUS_FAILED="ERROR"
SECANT_STATUS_SKIPPED="SKIPPED"
SECANT_STATUS_500="INTERNAL_FAILURE"

cloud_init()
{
    # only ON is supported atm
    CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
    source ${CONFIG_DIR}/cloud.conf

    export ONE_HOST ONE_XMLRPC
}

shutdown_vm()
{
    VM_ID=$1
    onevm shutdown --hard $VM_ID
    if [ $? -ne 0 ]; then
        logging $TEMPLATE_IDENTIFIER "Failed to shutdown VM $VM_ID." "ERROR"
    fi
}

delete_template_and_images()
{
    TEMPLATE_IDENTIFIER=$1

    timeout=$((SECONDS+(5*60)))
    while true; do
        if [ $SECONDS -gt $timeout ]; then
            logging $TEMPLATE_IDENTIFIER "Time-out reached while waiting for the VM to finish before deleting, exiting." "ERROR"
            return 1
        fi
        VM_IDS=($(onevm list | awk '{ print $1 }' | sed '1d'))
        found="no"
        for VM_ID in "${VM_IDS[@]}"; do
            templ_id=$(onevm show $VM_ID -x | xmlstarlet sel -t -v "//TEMPLATE_ID")
            [ "$templ_id" = "$TEMPLATE_IDENTIFIER" ] && found="yes"
        done
        [ "$found" = "no" ] && break
        sleep 10
    done

	# Get Template Images
	query='//DISK/IMAGE_ID/text()'
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

logging() {
    local log=$log_file

    if [ "$3" == "DEBUG" -a "$DEBUG" != "true" ]; then
        return 0
    fi

    if [ -z "$log" ]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] ${3}: $2"
    else
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] ${3}: $2" >> $log;
    fi
}

print_ascii_art(){
cat << "EOF"
     _______. _______   ______     ___      .__   __. .___________.
    /       ||   ____| /      |   /   \     |  \ |  | |           |
   |   (----`|  |__   |  ,----'  /  ^  \    |   \|  | `---|  |----`
    \   \    |   __|  |  |      /  /_\  \   |  . `  |     |  |
.----)   |   |  |____ |  `----./  _____  \  |  |\   |     |  |
|_______/    |_______| \______/__/     \__\ |__| \__|     |__|
EOF
}

remote_exec()
{
    HOST=$1
    USER=$2
    CMD=$3
    IN=$4
    OUT=$5

    SSH="ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=publickey"


    if [ -n "$USER" ]; then   
        $SSH ${USER}@${HOST} "$CMD" < $IN > $OUT
        [ $? -eq 0 ] && return 0
    fi
    for u in secant centos ubuntu; do
        $SSH ${u}@${HOST} "$CMD" < $IN > $OUT
        [ $? -eq 0 ] && return 0
    done

    return 1
}

perform_check()
{
    TEMPLATE_IDENTIFIER=$1
    VM_ID=$2
    FOLDER_TO_SAVE_REPORTS=$3
    PROBE=$4
    shift 4
    ipAddresses=("${@}")

    (
        ${SECANT_PATH}/probes/$PROBE/main.sh "${ipAddresses[0]}" "$FOLDER_TO_SAVE_REPORTS" "$TEMPLATE_IDENTIFIER" > $FOLDER_TO_SAVE_REPORTS/"$PROBE".stdout
        if [ $? -ne 0 ]; then
            logging $TEMPLATE_IDENTIFIER "Probe '$PROBE' failed to finish correctly" "ERROR"
            echo $SECANT_STATUS_500 | ${SECANT_PATH}/lib/reporter.py "$PROBE" >> $FOLDER_TO_SAVE_REPORTS/report || exit 1
            # we suppress the errors in probing scripts and don;t return error status
            exit 0
        fi
        ${SECANT_PATH}/lib/reporter.py "$PROBE" < $FOLDER_TO_SAVE_REPORTS/"$PROBE".stdout >> $FOLDER_TO_SAVE_REPORTS/report || exit 1
    )
    if [ $? -ne 0 ]; then
        logging $TEMPLATE_IDENTIFIER "Internal error while processing '$PROBE'" "ERROR"
        echo $SECANT_STATUS_500 | ${SECANT_PATH}/lib/reporter.py "$PROBE" >> $FOLDER_TO_SAVE_REPORTS/report
        return 1
    fi

    return 0
}

analyse_machine()
{
    TEMPLATE_IDENTIFIER=$1
    VM_ID=$2
    FOLDER_TO_SAVE_REPORTS=$3
    shift 3
    ipAddresses=("${@}")

    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > $FOLDER_TO_SAVE_REPORTS/report
    echo "<SECANT>" >> $FOLDER_TO_SAVE_REPORTS/report
    if [ -n "$SECANT_PROBES" ]; then
        IFS=',' read -ra PROBES <<< "$SECANT_PROBES"
        for PROBE in "${PROBES[@]}"; do
            perform_check "$TEMPLATE_IDENTIFIER" "$VM_ID" "$FOLDER_TO_SAVE_REPORTS" "$PROBE" "${ipAddresses[@]}"
        done
    fi

#    echo "<DATE>$(date +%s)</DATE>" >> $FOLDER_TO_SAVE_REPORTS/report
    echo "</SECANT>" >> $FOLDER_TO_SAVE_REPORTS/report
}

analyse_template()
{
    TEMPLATE_ID=$1
    TEMPLATE_IDENTIFIER=$2
    BASE_MPURI=$3
    FOLDER_PATH=$4

    RUN_WITH_CONTEXT_SCRIPT_PATH=${SECANT_PATH}/lib/run_with_contextualization.sh
    CTX_ADD_USER=${SECANT_PATH}/lib/ctx.add_user_secant
    CHECK_IF_CLOUD_INIT_RUN_FINISHED_SCRIPT_PATH=${SECANT_PATH}/lib/check_if_cloud_init_run_finished.py

    FOLDER_TO_SAVE_REPORTS=
    VM_ID=
    for RUN_WITH_CONTEXT_SCRIPT in false #true
    do
        if ! $RUN_WITH_CONTEXT_SCRIPT; then
            logging $TEMPLATE_IDENTIFIER "Start first run without contextualization script." "DEBUG"
            #Folder to save reports and logs during first run
            FOLDER_TO_SAVE_REPORTS=$FOLDER_PATH/1
            mkdir -p $FOLDER_TO_SAVE_REPORTS
            VM_ID=$(onetemplate instantiate $TEMPLATE_ID $CTX_ADD_USER)
        else
            logging $TEMPLATE_IDENTIFIER "Start second run with contextualization script." "DEBUG"
            #Folder to save reports and logs during second run
            FOLDER_TO_SAVE_REPORTS=$FOLDER_PATH/2
            mkdir -p $FOLDER_TO_SAVE_REPORTS
            RETURN_MESSAGE=$(./$RUN_WITH_CONTEXT_SCRIPT_PATH $TEMPLATE_ID $TEMPLATE_IDENTIFIER $FOLDER_TO_SAVE_REPORTS)
            if [[ "$RETURN_MESSAGE" == "1" ]]; then
                logging $TEMPLATE_IDENTIFIER "Could not instantiate template with contextualization!" "ERROR"
                continue
            fi
            VM_ID=$RETURN_MESSAGE
        fi

        if [[ $VM_ID =~ ^VM[[:space:]]ID:[[:space:]][0-9]+$ ]]; then
            VM_ID=$(echo $VM_ID | egrep -o '[0-9]+$')
            logging $TEMPLATE_IDENTIFIER "Template successfully instantiated, VM_ID: $VM_ID" "DEBUG"
        else
            logging $TEMPLATE_IDENTIFIER "$VM_ID." "ERROR"
            return 1
        fi

        # make sure VM is put down on exit (regardless how the function finishes)
        trap "shutdown_vm $VM_ID; trap - RETURN" RETURN

        lcm_state=$(onevm show $VM_ID -x | xmlstarlet sel -t -v '//LCM_STATE/text()' -n)
        vm_name=$(onevm show $VM_ID -x | xmlstarlet sel -t -v '//NAME/text()' -n)

        # Wait for Running status
        beginning=$(date +%s)
        while [ $lcm_state -ne 3 ]
        do
            now=$(date +%s)
            if [ $((now - beginning)) -gt $((60 * 30)) ]; then
                logging $TEMPLATE_IDENTIFIER "VM hasn't switched to the running status within 30 mins, exiting" "ERROR"
                return 1
            fi
            sleep 5s
            lcm_state=$(onevm show $VM_ID -x | xmlstarlet sel -t -v '//LCM_STATE/text()' -n)
        done

        logging $TEMPLATE_IDENTIFIER "Virtual Machine $vm_name is now running." "DEBUG"

        # Get IPs
        query='//NIC/IP/text()'
        ipAddresses=()
        while IFS= read -r entry; do
            ipAddresses+=( "$entry" )
        done < <(onevm show $VM_ID -x | xmlstarlet sel -t -v "$query" -n)
        if [ ${#ipAddresses[*]} -lt 1 ]; then
            logging $TEMPLATE_IDENTIFIER "The machine hasn't been assigned any IP address, exiting" "ERROR"
            return 1
        fi

        # Wait 80 seconds befor first test
        sleep 140

        if $RUN_WITH_CONTEXT_SCRIPT;
        then
            # Wait for contextualization
            # TODO edit SUGESTED USER instedad root
            RESULT=$(cat $CHECK_IF_CLOUD_INIT_RUN_FINISHED_SCRIPT_PATH | ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey root@${ipAddresses[0]} python - 2>&1)
            while [[ $RESULT == "1" ]]
            do
                sleep 10
                RESULT=$(cat $CHECK_IF_CLOUD_INIT_RUN_FINISHED_SCRIPT_PATH | ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey root@${ipAddresses[0]} python - 2>&1)
            done
            #logging $TEMPLATE_IDENTIFIER "$RESULT" "DEBUG"
        fi

        analyse_machine "$TEMPLATE_IDENTIFIER" "$VM_ID" "$FOLDER_TO_SAVE_REPORTS" "${ipAddresses[@]}"
        if [ $? -ne 0 ]; then
            logging $TEMPLATE_IDENTIFIER "Machine analysis didn't finish correctly" "ERROR"
            FAIL=yes
        fi

        if [ -z "$FAIL"]; then
            return 0
        else
            return 1
        fi

    done
}
