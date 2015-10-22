IP=$1
regex="^.*.Permission\sdenied\s[(][a-z,-]+[,]password[a-z,)].*"
ssh_reply=$(ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o PreferredAuthentications=none $IP 2>&1)
if [[ "$ssh_reply" =~ $regex ]]
then
    echo [`date +"%T"`] "[FAIL] SSH password authentication is allowed."
else
    echo [`date +"%T"`] "[OK] SSH password authentication is not allowed."
fi