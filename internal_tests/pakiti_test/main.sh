#!/bin/bash

VM_IP=$1
VM_ID=$2 # VM ID in OpenNebula


# Remotely run Pakiti client
echo [`date +"%T"`] "### Pakiti Report ###"
ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$VM_IP 'bash -s' < pakiti2-client-meta.sh > /tmp/tmp_$VM_ID
./pakiti2-client-meta-proxy.sh < /tmp/tmp_$VM_ID
rm -f /tmp/tmp_$VM_ID