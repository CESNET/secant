#!/usr/bin/env bash

IP=$1
FOLDER_PATH=$2


ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=none $IP &> $FOLDER_PATH/ssh_authentication_out
grep -q "Permission denied.*password" $FOLDER_PATH/ssh_authentication_out
if [ $? -eq 0 ]; then
    echo ERROR
    echo "SSH enables password-based authentication"
    exit 0
fi

echo OK
echo "SSH does not enable password-based authentication"
exit 0
