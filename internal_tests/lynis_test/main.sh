#!/usr/bin/env bash
VM_IP=$1
VM_ID=$2 # VM ID in OpenNebula
TEMPLATE_IDENTIFIER=$3
FOLDER_PATH=$4
LOGIN_AS_USER=$5
SHOULD_SECANT_SKIP_THIS_TEST=${6-false}

CURRENT_DIRECTORY=${PWD##*/}
if [[ "$CURRENT_DIRECTORY" == "lib" ]] ; then
    source ../conf/secant.conf
    source ../include/functions.sh
else
    if [[ "$CURRENT_DIRECTORY" == "secant" ]] ; then
        source conf/secant.conf
        source include/functions.sh
    else
        source ../../conf/secant.conf
        source ../../include/functions.sh
    fi
fi

if $SHOULD_SECANT_SKIP_THIS_TEST;
then
    logging $TEMPLATE_IDENTIFIER "Skip LYNIS_TEST." "DEBUG"
    printf "SKIP" | python reporter.py $TEMPLATE_IDENTIFIER
else
    scp -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey -r $lynis_directory/lynis/ "$LOGIN_AS_USER"@$VM_IP:/tmp > /tmp/scp.log 2>&1
    if [ ! "$?" -eq "0" ];
    then
        scp -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey -r $lynis_directory/lynis/ centos@$VM_IP:/tmp > /tmp/scp.log 2>&1
    fi
    if [ "$?" -eq "0" ];
    then
        LOGIN_AS_USER=centos
    else
        scp -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey -r $lynis_directory/lynis/ ubuntu@$VM_IP:/tmp > /tmp/scp.log 2>&1
        if [ "$?" -eq "0" ];
        then
            LOGIN_AS_USER=ubuntu
        else
            scp -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey -r $lynis_directory/lynis/ secant@$VM_IP:/tmp > /tmp/scp.log 2>&1
            logging $TEMPLATE_IDENTIFIER "Try to login as user secant" "INFO"
            if [ "$?" -eq "0" ];
            then
                LOGIN_AS_USER=secant
                logging $TEMPLATE_IDENTIFIER "Login as user secant was successful!" "INFO"
            fi
        fi
    fi
    if [ "$?" -eq "0" ];
    then
        if ! ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey "$LOGIN_AS_USER"@$VM_IP 'bash -s' < lynis-client.sh > $FOLDER_PATH/lynis_test.txt; then
            logging $TEMPLATE_IDENTIFIER] "During Lynis testing!" "ERROR"
        fi
        cat $FOLDER_PATH/lynis_test.txt | python reporter.py $TEMPLATE_IDENTIFIER
        if [ "$?" -eq "1" ];
        then
            printf "FAIL" | python reporter.py $TEMPLATE_IDENTIFIER
            logging $TEMPLATE_IDENTIFIER "LYNIS_TEST failed, error appeared in reporter." "ERROR"
        fi
    else
        printf "FAIL" | python reporter.py $TEMPLATE_IDENTIFIER
        logging $TEMPLATE_IDENTIFIER "LYNIS_TEST failed due to unsuccessful scp commmand!" "ERROR"

    fi
    rm -f /tmp/scp.log
fi