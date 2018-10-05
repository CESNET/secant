#!/usr/bin/env bash
# $1 : secant conf file path

#SECANT_CONF_PATH=${1-$DEFAULT_SECANT_CONF_PATH}
#source "$SECANT_CONF_PATH"

SECANT_STATUS_OK="OK"
SECANT_STATUS_FAILED="ERROR"
SECANT_STATUS_SKIPPED="SKIPPED"
SECANT_STATUS_500="INTERNAL_FAILURE"

delete_template_and_images()
{
    TEMPLATE_IDENTIFIER=$1

    timeout=$((SECONDS+(5*60)))
    while true; do
        if [ $SECONDS -gt $timeout ]; then
            logging $TEMPLATE_IDENTIFIER "Time-out reached while waiting for the VM to finish before deleting, proceeding to clean up the space anyway" "ERROR"
            break
        fi
        VM_IDS=($(cloud_get_vm_ids))
        if [ $? -ne 0 ]; then
            logging $TEMPLATE_IDENTIFIER "Failed to get a list of running VMs, proceeding to clean up the space anyway" "ERROR"
            break
        fi
        found="no"
        for VM_ID in "${VM_IDS[@]}"; do
            templ_id=$(cloud_vm_query "$VM_ID" "//TEMPLATE_ID")
            if [ $? -ne 0 ]; then
                logging $TEMPLATE_IDENTIFIER "Failed to get the template ID for VM $VM_ID" "WARNING"
                continue
            fi
            [ "$templ_id" = "$TEMPLATE_IDENTIFIER" ] && found="yes"
        done
        [ "$found" = "no" ] && break
        sleep 10
    done

    # Get Template Images
    images=($(cloud_template_query "$TEMPLATE_IDENTIFIER" "//DISK/IMAGE_ID/text()"))
    if [ $? -ne 0 ]; then
        logging "$TEMPLATE_IDENTIFIER" "Failed to query //DISK/IMAGE_ID/text()" "ERROR"
        return 1
    fi

    for image_name in "${images[@]}"
    do
        DELETE_IMAGE_RESULT=$(cloud_delete_image "$image_name")
        if [ $? -ne 0 ]; then
            logging $TEMPLATE_IDENTIFIER "Image: $image_name deleting failed." "ERROR"
            continue
        fi
        logging $TEMPLATE_IDENTIFIER "Image: $image_name successfully deleted." "DEBUG"
    done

    DELETE_TEMPLATE_RESULT=$(cloud_delete_template "$TEMPLATE_IDENTIFIER")
    if [ $? -ne 0 ]; then
        logging $TEMPLATE_IDENTIFIER "Template: $TEMPLATE_IDENTIFIER deleting failed." "ERROR"
        return 1
    fi
    logging $TEMPLATE_IDENTIFIER "Template: $TEMPLATE_IDENTIFIER successfully deleted." "DEBUG"
}

logging() {
    local log=$log_file

    if [ "$3" == "DEBUG" -a "$DEBUG" != "true" ]; then
        return 0
    fi

    now=`date +"%Y-%m-%d %H:%M:%S"`
    if [ -z "$log" ]; then
        echo "$now [$1] ${3}: $2"
    else
        echo "$now [$1] ${3}: $2" >> $log
        if [ "$3" == "ERROR" ]; then
            echo "$now [$1] ${3}: $2" >&2
        fi
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
    $SSH secant@${HOST} "$CMD" < $IN > $OUT
    [ $? -eq 0 ] && return 0

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
        ${SECANT_PATH}/probes/$PROBE/main "${ipAddresses[0]}" "$FOLDER_TO_SAVE_REPORTS" "$TEMPLATE_IDENTIFIER" > $FOLDER_TO_SAVE_REPORTS/"$PROBE".stdout
        if [ $? -ne 0 ]; then
            logging $TEMPLATE_IDENTIFIER "Probe '$PROBE' failed to finish correctly" "ERROR"
            (echo $SECANT_STATUS_500; echo "Probe $PROBE failed to finish correctly") | ${SECANT_PATH}/tools/reporter.py "$PROBE" >> $FOLDER_TO_SAVE_REPORTS/report || exit 1
            # we suppress the errors in probing scripts and don;t return error status
            exit 0
        fi
        ${SECANT_PATH}/tools/reporter.py "$PROBE" < $FOLDER_TO_SAVE_REPORTS/"$PROBE".stdout >> $FOLDER_TO_SAVE_REPORTS/report || exit 1
    )
    if [ $? -ne 0 ]; then
        logging $TEMPLATE_IDENTIFIER "Internal error while processing '$PROBE'" "ERROR"
        echo $SECANT_STATUS_500 | ${SECANT_PATH}/tools/reporter.py "$PROBE" >> $FOLDER_TO_SAVE_REPORTS/report
        return 1
    fi

    return 0
}

analyse_machine()
{
    CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
    source $CONFIG_DIR/probes.conf

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

    CTX_ADD_USER=${SECANT_PATH}/conf/ctx.add_user_secant

    FOLDER_TO_SAVE_REPORTS=
    VM_ID=
    logging $TEMPLATE_IDENTIFIER "Starting template analysis." "DEBUG"
    #Folder to save reports and logs during first run
    FOLDER_TO_SAVE_REPORTS=$FOLDER_PATH/1
    mkdir -p $FOLDER_TO_SAVE_REPORTS
    VM_ID=$(cloud_start_vm "$TEMPLATE_ID" "$CTX_ADD_USER")
    if [ $? -ne 0 ]; then
        logging $TEMPLATE_IDENTIFIER "Failed to instantiate template." "ERROR"
        return 1
    fi

    if [[ $VM_ID =~ ^VM[[:space:]]ID:[[:space:]][0-9]+$ ]]; then
        VM_ID=$(echo $VM_ID | egrep -o '[0-9]+$')
        logging $TEMPLATE_IDENTIFIER "Template successfully instantiated, VM_ID: $VM_ID" "DEBUG"
    else
        logging $TEMPLATE_IDENTIFIER "$VM_ID." "ERROR"
        return 1
    fi

    # make sure VM is put down on exit (regardless how the function finishes)
    trap "logging $TEMPLATE_IDENTIFIER 'Shutting down VM $VM_ID.' 'DEBUG'; cloud_shutdown_vm "$VM_ID"; trap - RETURN" RETURN

    lcm_state=$(cloud_vm_query "$VM_ID" "//LCM_STATE/text()")
    if [ $? -ne 0 ]; then
        logging $TEMPLATE_IDENTIFIER "Failed to query //LCM_STATE/text() on VM with id $VM_ID" "ERROR"
        return 1
    fi
    vm_name=$(cloud_vm_query "$VM_ID" "//NAME/text()")
    if [ $? -ne 0 ]; then
        logging $TEMPLATE_IDENTIFIER "Failed to query //NAME/text() on VM with id $VM_ID" "ERROR"
        return 1
    fi

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
        lcm_state=$(cloud_vm_query "$VM_ID" "//LCM_STATE/text()")
        if [ $? -ne 0 ]; then
            logging $TEMPLATE_IDENTIFIER "Failed to query //LCM_STATE/text() on VM with id $VM_ID" "ERROR"
            return 1
        fi
    done

    logging $TEMPLATE_IDENTIFIER "Virtual Machine $vm_name is now running." "DEBUG"

    # Get IPs
    ipAddresses=($(cloud_vm_query "$VM_ID" "//NIC/IP/text()"))
    if [ $? -ne 0 ]; then
        logging $TEMPLATE_IDENTIFIER "Failed to query //NIC/IP/text()" "ERROR"
        return 1
    fi
    if [ ${#ipAddresses[*]} -lt 1 ]; then
        logging $TEMPLATE_IDENTIFIER "The machine hasn't been assigned any IP address, exiting" "ERROR"
        return 1
    fi

    IP="${ipAddresses[0]}"
    timeout=$((SECONDS+(5*60)))
    is_ssh=false
    while true; do
        if [ $SECONDS -gt $timeout ]; then
            logging $TEMPLATE_ID "VM is not running or ssh is not opened. Analyse running..." "INFO"
            break
        fi
        nmap -P0 -oG - -T 4 -n $IP | tr -d '\n' | grep -E 'Status: Up.*Ports: 22/open'
        if [ $? -eq 0 ]; then
            is_ssh=true
            break
        fi
        nmap -oG - -T 4 -n $IP | tr -d '\n' | grep -E 'Status: Up.*Ports: 22/open'
        if [ $? -eq 0 ]; then
            is_ssh=true
            break
        fi
        sleep 10
    done

    timeout=$((SECONDS+(10*60)))
    have_cloud_init=true
    if $is_ssh; then
        while true; do
            if [ $SECONDS -gt $timeout ]; then
                logging $TEMPLATE_ID "Cloud-init status is not 'done'." "ERROR"
                return 1
            fi
            ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey secant@$IP /bin/true
            if [ $? -ne 0 ]; then
                logging $TEMPLATE_ID "SSH login with user secant is not working." "ERROR"
                break
            fi
            if $have_cloud_init; then
                CLOUD_INIT=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey secant@$IP cloud-init status)
                if [ $? -ne 0 ]; then
                    logging $TEMPLATE_ID "Cloud-init missing on VM. Analyse running..." "INFO"
                    have_cloud_init=false
                    continue
                fi
            else
                cloud-init_status
            fi
            echo $CLOUD_INIT | grep -q 'done'
            if [ $? -eq 0 ]; then
                break
            fi
        done
    fi

    analyse_machine "$TEMPLATE_IDENTIFIER" "$VM_ID" "$FOLDER_TO_SAVE_REPORTS" "${ipAddresses[@]}"
    if [ $? -ne 0 ]; then
        logging $TEMPLATE_IDENTIFIER "Machine analysis didn't finish correctly" "ERROR"
        return 1
    fi
    logging $TEMPLATE_IDENTIFIER "Machine analysis finished correctly" "INFO"
}

cloud-init_status() {
    scp -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey secant@$IP:/var/lib/cloud/data/status.json /tmp/${TEMPLATE_ID}_status.json
    if [ $? -ne 0 ]; then
        sleep 10
        continue
    else
        scp -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey secant@$IP:/var/lib/cloud/data/status.json /tmp/${TEMPLATE_ID}_result.json
        if [ $? -ne 0 ]; then
            sleep 10
            continue
        else
            ${SECANT_PATH}/tools/cloud-init_status.py /tmp/${TEMPLATE_ID}_status.json
            ret=$?
            if [ $ret -eq 0 ]; then
                CLOUD_INIT="done"
            fi
            if [ $ret -eq 1 ]; then
                sleep 10
                continue
            fi
            if [ $ret -eq 2 ]; then
                rm /tmp/${TEMPLATE_ID}_status.json /tmp/${TEMPLATE_ID}_result.json
                logging $TEMPLATE_ID "Cloud-init ended with error." "INFO"
                break
            fi
        fi
    fi
    rm /tmp/${TEMPLATE_ID}_status.json /tmp/${TEMPLATE_ID}_result.json 2> /dev/null
}
