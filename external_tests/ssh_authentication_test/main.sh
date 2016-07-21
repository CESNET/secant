IP=$1
VM_ID=$2
TEMPLATE_IDENTIFIER=$3
SSH_PORT_STATUS=`nmap $IP -PN -p ssh | grep open`
if [ ! -z "$SSH_PORT_STATUS" ]; then
    ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=none $IP 2>&1 | python reporter.py $TEMPLATE_IDENTIFIER
else
    SSH_PORT_STATUS=`nmap $IP -PN -p ssh | grep filtered`
    if [ ! -z "$SSH_PORT_STATUS" ]; then
        echo "SSH port reported as filtered" | python reporter.py $TEMPLATE_IDENTIFIER
    fi
fi
