#!/bin/bash

debug() { echo "[DEBUG] $*" >&2; }

TEMPLATE_ID=$1
VM_ID=$(onetemplate instantiate $TEMPLATE_ID)
source secant.conf

if [[ $VM_ID =~ ^VM[[:space:]]ID:[[:space:]][0-9]+$ ]]; then
  VM_ID=$(echo $VM_ID | egrep -o '[0-9]+$')
  echo "[INFO] Template successfully instantiated: $TEMPLATE_ID"
else
  echo $VM_ID
  exit 1
fi

TEMP_FILE_PATH="/tmp/tmp_$VM_ID.xml"

onevm show $VM_ID -x > $TEMP_FILE_PATH
lcm_state=$(xmlstarlet sel -t -v '//LCM_STATE/text()' -n $TEMP_FILE_PATH)
vm_name=$(xmlstarlet sel -t -v '//NAME/text()' -n $TEMP_FILE_PATH)

# Wait for Running status
while [ $lcm_state -ne 3 ]
do
	sleep 5s
	onevm show $VM_ID -x > $TEMP_FILE_PATH
	lcm_state=$(xmlstarlet sel -t -v '//LCM_STATE/text()' -n $TEMP_FILE_PATH)
done

echo "[INFO] VM: $vm_name is now running"

# Get IPs
query='//NIC/IP/text()'
ipAddresses=()
while IFS= read -r entry; do
  ipAddresses+=( "$entry" )
done < <(xmlstarlet sel -t -v "$query" -n $TEMP_FILE_PATH)

number_of_attempts=0
while [ -z "$ip_address_for_ssh" ] && [ $number_of_attempts -lt 7 ]
do
	ip_address_for_ssh=""
	for ip in "${ipAddresses[@]}"
	do
		ssh_state=$(nmap $ip -PN -p ssh | egrep -o 'open|closed|filtered')
		if [ "$ssh_state" == "open" ]; then
			echo "[INFO] Open SSH port has been successfully detected"
			ip_address_for_ssh=$ip
			break;
		fi
	done
	
	if [ -z "$ip_address_for_ssh" ]; then
		((number_of_attempts++))
		sleep 5s
	fi
done

if [ -z "$ip_address_for_ssh" ]; then
	echo "[ERROR] TemplateID: $TEMPLATE_ID Open SSH port has not been detected"
	onevm delete $VM_ID
	exit 1
fi

# Check if directory for reports already exist, if not create
if [[ ! -e $reports_directory ]]; then
    mkdir $reports_directory
fi

#Run external tests
for filename in external_tests/*/
do
 (cd $filename && ./main.sh $ip_address_for_ssh $VM_ID >> $reports_directory/report_$TEMPLATE_ID)
done

#Run internal tests
for filename in internal_tests/*/
do
 (cd $filename && ./main.sh $ip_address_for_ssh $VM_ID >> $reports_directory/report_$TEMPLATE_ID)
done

debug "Successfully reported"

onevm delete $VM_ID
rm $TEMP_FILE_PATH
