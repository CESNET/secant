#!/usr/bin/env bash
# $1 : secant conf file path

#SECANT_CONF_PATH=${1-$DEFAULT_SECANT_CONF_PATH}
#source "$SECANT_CONF_PATH"

logging() {
    local log=$log_file
    [ -n "$log" ] || log=/dev/stdout

    if [[ $3 == "INFO" ]]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] INFO: $2" >> $log;
    fi

    if [[ $3 == "ERROR" ]]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] ERROR: $2" >> $log;
    fi

    if [[ $3 == "DEBUG" ]] && [ "$DEBUG" = "true" ]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] DEBUG: $2" >> $log;
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

    SSH="ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/nulls -o PreferredAuthentications=publickey"

    $SSH ${USER}@${HOST} "$CMD" < $IN > $OUT
    [ $? -eq 0 ] && return 0

    for u in secant centos ubuntu; do
        $SSH ${u}@${HOST} "$CMD" < $IN > $OUT
        [ $? -eq 0 ] && return 0
    done

    return 1
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

    logging $TEMPLATE_IDENTIFIER "Starting external tests..." "DEBUG"
    for filename in $EXTERNAL_TESTS_FOLDER_PATH/*; do
        (
            cd $filename || exit 1
            name=$($filename/get_name) || exit 1
            ./main.sh ${ipAddresses[0]} $VM_ID $TEMPLATE_IDENTIFIER $FOLDER_TO_SAVE_REPORTS > $FOLDER_TO_SAVE_REPORTS/TMP || exit 1
            ../../lib/reporter.py "$name" < $FOLDER_TO_SAVE_REPORTS/TMP >> $FOLDER_TO_SAVE_REPORTS/report || exit 1
        )
        ret=$?
        rm -f $FOLDER_TO_SAVE_REPORTS/TMP
        if [ $ret -ne 0 ]; then
            logging $TEMPLATE_IDENTIFIER "Test $filename failed" "ERROR"
            exit 1
        fi
    done

    number_of_attempts=0
    ip_address_for_ssh=
    while [ -z "$ip_address_for_ssh" ] && [ $number_of_attempts -lt 15 ]; do
        ip_address_for_ssh=""
        for ip in "${ipAddresses[@]}"; do
            ssh_state=$(nmap $ip -PN -p ssh | egrep -o 'open|closed|filtered')
            if [ "$ssh_state" == "open" ]; then
                logging $TEMPLATE_IDENTIFIER "Open SSH port has been successfully detected, IP address: $ip" "DEBUG"
                ip_address_for_ssh=$ip
                break;
            fi
        done
        if [ -z "$ip_address_for_ssh" ]; then
            ((number_of_attempts++))
            sleep 5s
        fi
    done

    #Run internal tests
    if [ -z "$ip_address_for_ssh" ]; then
        logging $TEMPLATE_IDENTIFIER "Open SSH port has not been detected, skip internal tests." "DEBUG"
        for filename in $INTERNAL_TESTS_FOLDER_PATH/*/; do
            (name=$($filename/get_name) && echo SKIP | ../lib/reporter.py $name >> $FOLDER_TO_SAVE_REPORTS/report)
        done
    else
        LOGIN_AS_USER="root"
        ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey "$ip_address_for_ssh" 2&> /tmp/$TEMPLATE_IDENTIFIER
        SUGGESTED_USER=$(cat /tmp/$TEMPLATE_IDENTIFIER | grep -i "Please login as the user*" | sed -e 's/Please login as the user \"\(.*\)\" rather than the user \"root\"./\1/')
        if [ ! -z "$SUGGESTED_USER" ]; then
            LOGIN_AS_USER="$SUGGESTED_USER"
        fi
        logging $TEMPLATE_IDENTIFIER "Starting internal tests... IP: $ip_address_for_ssh, login as user: $LOGIN_AS_USER" "DEBUG"
        for filename in $INTERNAL_TESTS_FOLDER_PATH/*/; do
            (
                cd $filename || exit 1
                name=$($filename/get_name) || exit 1
                ./main.sh $ip_address_for_ssh $VM_ID $TEMPLATE_IDENTIFIER $FOLDER_TO_SAVE_REPORTS $LOGIN_AS_USER > $FOLDER_TO_SAVE_REPORTS/TMP || exit 1
                ../../lib/reporter.py "$name" < $FOLDER_TO_SAVE_REPORTS/TMP >> $FOLDER_TO_SAVE_REPORTS/report || exit 1
            )
            ret=$?
            rm -f $FOLDER_TO_SAVE_REPORTS/TMP
            if [ $ret -ne 0 ]; then
                logging $TEMPLATE_IDENTIFIER "Test $filename failed" "ERROR"
                exit 1
            fi
        done
    fi

    echo "<DATE>$(date +%s)</DATE>" >> $FOLDER_TO_SAVE_REPORTS/report
    echo "</SECANT>" >> $FOLDER_TO_SAVE_REPORTS/report
}

analyse_template()
{
    TEMPLATE_ID=$1
    TEMPLATE_IDENTIFIER=$2
    BASE_MPURI=$3
    FOLDER_PATH=$4

    # Move to secant core (?):
    # Check from which folder script is running
    CURRENT_DIRECTORY=${PWD##*/}
    EXTERNAL_TESTS_FOLDER_PATH=
    INTERNAL_TESTS_FOLDER_PATH=

    if [[ "$CURRENT_DIRECTORY" == "lib" ]] ; then
        EXTERNAL_TESTS_FOLDER_PATH=../external_tests
        INTERNAL_TESTS_FOLDER_PATH=../internal_tests
        LIB_FOLDER_PATH=""
        source ../include/functions.sh
        RUN_WITH_CONTEXT_SCRIPT_PATH=run_with_contextualization.sh
        CTX_ADD_USER=ctx.add_user_secant
        CHECK_IF_CLOUD_INIT_RUN_FINISHED_SCRIPT_PATH=check_if_cloud_init_run_finished.py
    else
        EXTERNAL_TESTS_FOLDER_PATH=external_tests
        INTERNAL_TESTS_FOLDER_PATH=internal_tests
        source include/functions.sh
        LIB_FOLDER_PATH="lib"
        RUN_WITH_CONTEXT_SCRIPT_PATH=lib/run_with_contextualization.sh
        CTX_ADD_USER=lib/ctx.add_user_secant
        CHECK_IF_CLOUD_INIT_RUN_FINISHED_SCRIPT_PATH=lib/check_if_cloud_init_run_finished.py
    fi

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
            exit 1
        fi

        lcm_state=$(onevm show $VM_ID -x | xmlstarlet sel -t -v '//LCM_STATE/text()' -n)
        vm_name=$(onevm show $VM_ID -x | xmlstarlet sel -t -v '//NAME/text()' -n)

        # Wait for Running status
        while [ $lcm_state -ne 3 ]
        do
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
            logging $TEMPLATE_IDENTIFIER "Machine analysis didn't succeed" "ERROR"
        fi

        logging $TEMPLATE_IDENTIFIER "Delete Virtual Machine $VM_ID." "DEBUG"
        #onevm delete $VM_ID
        onevm shutdown --hard $VM_ID

        # Wait VM to shutdown before delete image
        if $RUN_WITH_CONTEXT_SCRIPT; then
            VM_STATE=$(onevm show $VM_ID -x | xmlstarlet sel -t -v '//LCM_STATE/text()' -n)
            while [[ $VM_STATE -ne 0 ]]
            do
                sleep 5s
                VM_STATE=$(onevm show $VM_ID -x | xmlstarlet sel -t -v '//LCM_STATE/text()' -n)
            done
        fi
    done
}
