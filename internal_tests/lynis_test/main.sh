#!/usr/bin/env bash
VM_IP=$1
VM_ID=$2 # VM ID in OpenNebula

scp -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -r Lynis/ root@$VM_IP:/tmp
ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$VM_IP 'bash -s' < lynis-client.sh
