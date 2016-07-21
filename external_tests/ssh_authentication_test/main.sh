IP=$1
VM_ID=$2
TEMPLATE_IDENTIFIER=$3
FOLDER_PATH=$4
SHOULD_SECANT_SKIP_THIS_TEST=${5-false}

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
    python reporter.py $TEMPLATE_IDENTIFIER "SKIP"
    logging $TEMPLATE_IDENTIFIER "Skip SSH_AUTHENTICATION_TEST." "DEBUG"
else
    SSH_PORT_STATUS=`nmap $IP -PN -p ssh | grep open`
    if [ ! -z "$SSH_PORT_STATUS" ]; then
        ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=none $IP 2>&1 | python reporter.py $TEMPLATE_IDENTIFIER
    else
        SSH_PORT_STATUS=`nmap $IP -PN -p ssh | grep filtered`
        if [ ! -z "$SSH_PORT_STATUS" ]; then
            echo "SSH port reported as filtered" | python reporter.py $TEMPLATE_IDENTIFIER
        fi
    fi
fi
