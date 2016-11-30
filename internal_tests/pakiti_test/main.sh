#!/bin/bash

VM_IP=$1
VM_ID=$2 # VM ID in OpenNebul
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
    printf "SKIP" | python reporter.py $TEMPLATE_IDENTIFIER
    logging $TEMPLATE_IDENTIFIER "Skip PAKITI_TEST." "DEBUG"
else
    # Remotely run Pakiti client
    ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey "$LOGIN_AS_USER"@$VM_IP 'bash -s' < pakiti2-client-meta.sh > $FOLDER_PATH/pakiti_test-pkgs.txt
    if [ ! -s $FOLDER_PATH/pakiti_test-pkgs.txt ]
    then
        ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey centos@$VM_IP 'bash -s' < pakiti2-client-meta.sh > $FOLDER_PATH/pakiti_test-pkgs.txt
    fi

    if [ ! -s $FOLDER_PATH/pakiti_test-pkgs.txt ]
    then
        ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=publickey ubuntu@$VM_IP 'bash -s' < pakiti2-client-meta.sh > $FOLDER_PATH/pakiti_test-pkgs.txt
    fi

    # Check if pakiti-pkg file is empty
    if [ ! -s $FOLDER_PATH/pakiti_test-pkgs.txt ]
    then
            printf "FAIL" | python reporter.py $TEMPLATE_IDENTIFIER
            logging $TEMPLATE_IDENTIFIER "PAKITI_TEST failed, due to empty report file." "ERROR"
    else
        sed -i -e 's/host=""/host="'$TEMPLATE_IDENTIFIER'"/g' $FOLDER_PATH/pakiti_test-pkgs.txt
        ./pakiti2-client-meta-proxy.sh < $FOLDER_PATH/pakiti_test-pkgs.txt > $FOLDER_PATH/pakiti_test-result.txt 2>&1

        if [ "$?" -eq "0" ];
        then
            cat $FOLDER_PATH/pakiti_test-result.txt | python reporter.py $TEMPLATE_IDENTIFIER
            if [ "$?" -eq "1" ];
            then
                printf "FAIL" | python reporter.py $TEMPLATE_IDENTIFIER
                logging $TEMPLATE_IDENTIFIER "PAKITI_TEST failed, error appeared in reporter." "ERROR"
            fi
        else
            printf "FAIL" | python reporter.py $TEMPLATE_IDENTIFIER
            logging $TEMPLATE_IDENTIFIER "PAKITI_TEST failed while sending data to the Pakiti server!" "ERROR"
        fi
    fi
fi
