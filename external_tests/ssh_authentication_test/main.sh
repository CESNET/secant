IP=$1
SSH_PORT_STATUS=`nmap $IP -PN -p ssh | grep open`
if [ ! -z "$SSH_PORT_STATUS" ]; then
    ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=none $IP 2>&1 | python reporter.py
fi
