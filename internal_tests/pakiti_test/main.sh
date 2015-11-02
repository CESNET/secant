#!/bin/bash

VM_IP=$1
VM_ID=$2 # VM ID in OpenNebula


# Remotely run Pakiti client
echo [`date +"%T"`] "### Pakiti Report ###"
ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$VM_IP 'bash -s' < pakiti2-client-meta.sh > /tmp/tmp_$VM_ID

PAKITI_REPORT=$(./pakiti2-client-meta-proxy.sh < /tmp/tmp_$VM_ID)

if [[ `echo $PAKITI_REPORT | head -c 2` == "OK" ]];then
	PAKITI_REPORT=$(echo $PAKITI_REPORT | cut -c3-)
    if [[ -z $PAKITI_REPORT ]];then
    	echo "No vulnerable packages are detected."
    else
      echo "Name, Installed version, Architecture"
      counter=1
      row=""
      IFS=' ' read -ra PKGS <<< "$PAKITI_REPORT"
      for i in "${PKGS[@]}"; do
          if ! (($counter % 3)); then
              row+="$i "
          else
              row+="$i, "
          fi

          if ! (($counter % 3)); then
              echo -e $row
              row=""
          fi
          counter=$((counter+1))
      done
    fi
  else
  	echo "Pakiti error appears during data processing."
fi
#rm -f /tmp/tmp_$VM_ID