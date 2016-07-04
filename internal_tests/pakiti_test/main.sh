#!/bin/bash

VM_IP=$1
VM_ID=$2 # VM ID in OpenNebul
TEMPLATE_IDENTIFIER=$3
FOLDER_PATH=$4

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

# Remotely run Pakiti client
ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$VM_IP 'bash -s' < pakiti2-client-meta.sh > $FOLDER_PATH/pakiti_test-pkgs.txt

./pakiti2-client-meta-proxy.sh < $FOLDER_PATH/pakiti_test-pkgs.txt > $FOLDER_PATH/pakiti_test-result.txt 2>&1

if [ "$?" -eq "0" ];
then
    cat $FOLDER_PATH/pakiti_test-result.txt | python reporter.py $TEMPLATE_IDENTIFIER
else
    logging "[$TEMPLATE_IDENTIFIER] ERROR: occured while sending data to the Pakiti server!"
fi
#| python reporter.py $TEMPLATE_IDENTIFIER

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