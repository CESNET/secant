#!/bin/bash

source secant.conf
source include/functions.sh

delete_template_and_images(){
	TEMPLATE_ID=$1
	TEMP_FILE_PATH="/tmp/tmp_$TEMPLATE_ID.xml"
	onetemplate show $TEMPLATE_ID -x > $TEMP_FILE_PATH

	# Get Template Images
	query='//DISK/IMAGE/text()'
	images=()
	while IFS= read -r entry; do
	  images+=( "$entry" )
	done < <(xmlstarlet sel -t -v "$query" -n $TEMP_FILE_PATH)

	for image_name in "${images[@]}"
	do
		oneimage delete $image_name
		logging "[$TEMPLATE_ID] INFO: Delete Image $image_name."
	done

	onetemplate delete $TEMPLATE_ID
	logging "[$TEMPLATE_ID] INFO: Delete Template $TEMPLATE_ID."
	rm $TEMP_FILE_PATH
}
TEMPLATE_ID=$1
VM_ID=$(onetemplate instantiate $TEMPLATE_ID)


if [[ $VM_ID =~ ^VM[[:space:]]ID:[[:space:]][0-9]+$ ]]; then
  VM_ID=$(echo $VM_ID | egrep -o '[0-9]+$')
  logging "[$TEMPLATE_ID] INFO: Template successfully instantiated."
else
  logging "[$TEMPLATE_ID] ERROR: $VM_ID."
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

logging "[$TEMPLATE_ID] INFO: Virtual Machine $vm_name is now running."


# Get IPs
query='//NIC/IP/text()'
ipAddresses=()
while IFS= read -r entry; do
  ipAddresses+=( "$entry" )
done < <(xmlstarlet sel -t -v "$query" -n $TEMP_FILE_PATH)

number_of_attempts=0
while [ -z "$ip_address_for_ssh" ] && [ $number_of_attempts -lt 15 ]
do
	ip_address_for_ssh=""
	for ip in "${ipAddresses[@]}"
	do
		ssh_state=$(nmap $ip -PN -p ssh | egrep -o 'open|closed|filtered')
		if [ "$ssh_state" == "open" ]; then
		    logging "[$TEMPLATE_ID] INFO: Open SSH port has been successfully detected, IP address: $ip"
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
    logging "[$TEMPLATE_ID] ERROR: Open SSH port has not been detected."
	onevm delete $VM_ID
	exit 1
fi

# Check if directory for reports already exist, if not create
if [[ ! -e $reports_directory ]]; then
    mkdir $reports_directory
fi

# Wait 25 seconds befor first test
sleep 25

# send sigstop to cloud-init
logging "[$TEMPLATE_ID] DEBUG: Send SIGSTOP to cloud-init."
ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$ip_address_for_ssh 'kill -SIGSTOP `pgrep cloud-init`'

CLOUD_INIT_PROCESS_STATUS=$(ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$ip_address_for_ssh 'ps cax | grep cloud-init')
CLOUD_INIT_PROCESS_STATUS=$(echo $CLOUD_INIT_PROCESS_STATUS | awk '{print $3}')

if [ "$CLOUD_INIT_PROCESS_STATUS" == "T" ]; then
	logging "[$TEMPLATE_ID] DEBUG: Process cloud-init successfully stopped."
	else
	logging "[$TEMPLATE_ID] DEBUG: Process cloud-init still running."
fi

# Create file to save the report
REPORT_PATH="$reports_directory/report_$TEMPLATE_ID"
if [[ -e $REPORT_PATH ]] ; then
    i=2
    while [[ -e $REPORT_PATH-$i ]] ; do
        let i++
    done
    REPORT_PATH=$REPORT_PATH-$i
fi

#Run external tests
logging "[$TEMPLATE_ID] INFO: Starting external tests..."
for filename in external_tests/*/
do
 (cd $filename && ./main.sh $ip_address_for_ssh $VM_ID >> $REPORT_PATH)
done

#Run internal tests
logging "[$TEMPLATE_ID] INFO: Starting internal tests..."
for filename in internal_tests/*/
do
 (cd $filename && ./main.sh $ip_address_for_ssh $VM_ID >> $REPORT_PATH)
done

logging "[$TEMPLATE_ID] INFO: Delete Virtual Machine $VM_ID."
onevm delete $VM_ID
#delete_template_and_images $TEMPLATE_ID
rm $TEMP_FILE_PATH
