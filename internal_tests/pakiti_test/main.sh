#!/bin/bash

VM_IP=$1
VM_ID=$2 # VM ID in OpenNebula
#PAKITI_REPORT=/tmp/tmp_pakiti_report_$VM_ID

# Remotely run Pakiti client
#echo [`date +"%T"`] "### Pakiti Report ###"
ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$VM_IP 'bash -s' < pakiti2-client-meta.sh > /tmp/tmp_$VM_ID

./pakiti2-client-meta-proxy.sh < /tmp/tmp_$VM_ID | python reporter.py

#if [[ `cat $PAKITI_REPORT | head -c 2` == "OK" ]];then
#    sed -i -e "1d" $PAKITI_REPORT #Remove OK
#    if [[ `head -n 1 $PAKITI_REPORT` == '' ]];then
#    	echo "No vulnerable packages are detected."
#    else
#        echo "Name, Installed version, Architecture"
#        while IFS='' read -r line || [[ -n "$line" ]]; do
#            echo $line | sed 's/ /,/g'
#        done < $PAKITI_REPORT
#    fi
#else
#  echo "Pakiti error appears during data processing."
#fi
#
#rm -f $PAKITI_REPORT
#rm -f /tmp/tmp_$VM_ID