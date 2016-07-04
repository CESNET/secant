#!/bin/bash

TEMPLATE_ID=$1
TEMPLATE_IDENTIFIER=$2

#DEFAULT_SECANT_CONF_PATH=../conf/secant.conf
#SECANT_CONF_PATH=${3-$DEFAULT_SECANT_CONF_PATH}
#source "$SECANT_CONF_PATH"
#
#DEFAULT_FUNCTIONS_FILE_PATH=../include/functions.sh
#FUNCTIONS_FILE_PATH=${4-$DEFAULT_FUNCTIONS_FILE_PATH}
#source "$FUNCTIONS_FILE_PATH" ../conf/secant.conf

# Check from which folder script is running
CURRENT_DIRECTORY=${PWD##*/}
EXTERNAL_TESTS_FOLDER_PATH=
INTERNAL_TESTS_FOLDER_PATH=

if [[ "$CURRENT_DIRECTORY" == "lib" ]] ; then
	EXTERNAL_TESTS_FOLDER_PATH=../external_tests
	INTERNAL_TESTS_FOLDER_PATH=../internal_tests
	source ../conf/secant.conf
	source ../include/functions.sh
else
	EXTERNAL_TESTS_FOLDER_PATH=external_tests
	INTERNAL_TESTS_FOLDER_PATH=internal_tests
	source conf/secant.conf
	source include/functions.sh
fi

# Create folder to save the assessment result
FOLDER_PATH=$reports_directory/$TEMPLATE_IDENTIFIER

if [[ ! -d $FOLDER_PATH ]] ; then
	i=2
	while [[ -d $FOLDER_PATH-$i ]] ; do
       	let i++
  	done
    FOLDER_PATH=$FOLDER_PATH-$i
    mkdir -p $FOLDER_PATH
fi

delete_template_and_images(){
	# Get Template Images
	query='//DISK/IMAGE/text()'
	images=()
	while IFS= read -r entry; do
	  images+=( "$entry" )
	done < <(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "$query" -n)

	for image_name in "${images[@]}"
	do
		oneimage delete $image_name
		logging "[$TEMPLATE_IDENTIFIER] INFO: Delete Image $image_name."
	done

	onetemplate delete $TEMPLATE_ID
	logging "[$TEMPLATE_IDENTIFIER] INFO: Delete Template $TEMPLATE_ID."
}

FOLDER_TO_SAVE_REPORTS=
for RUN_WITH_CONTEXT_SCRIPT in false true
do
	if ! $RUN_WITH_CONTEXT_SCRIPT; then
		logging "[$TEMPLATE_IDENTIFIER] INFO: Start first run without contextualization script."
		#Folder to save reports and logs during first run
		FOLDER_TO_SAVE_REPORTS=$FOLDER_PATH/1
		mkdir -p $FOLDER_TO_SAVE_REPORTS
	else
		logging "[$TEMPLATE_IDENTIFIER] INFO: Start second run with contextualization script."
		#Folder to save reports and logs during second run
		FOLDER_TO_SAVE_REPORTS=$FOLDER_PATH/2
		mkdir -p $FOLDER_TO_SAVE_REPORTS
	fi

	VM_ID=$(onetemplate instantiate $TEMPLATE_ID)
	if [[ $VM_ID =~ ^VM[[:space:]]ID:[[:space:]][0-9]+$ ]]; then
	  VM_ID=$(echo $VM_ID | egrep -o '[0-9]+$')
	  logging "[$TEMPLATE_IDENTIFIER] INFO: Template successfully instantiated."
	else
	  logging "[$TEMPLATE_IDENTIFIER] ERROR: $VM_ID."
	  exit 1
	fi

	lcm_state=$(onevm show $VM_ID -x | xmlstarlet sel -t -v '//LCM_STATE/text()' -n)
	vm_name=$(onevm show $VM_ID -x | xmlstarlet sel -t -v '//NAME/text()' -n)

	# Wait for Running status
	while [ $lcm_state -ne 3 ]
	do
		sleep 5s
		lcm_state=$(onevm show $VM_ID -x | xmlstarlet sel -t -v '//LCM_STATE/text()' -n)
	done

	logging "[$TEMPLATE_IDENTIFIER] INFO: Virtual Machine $vm_name is now running."


	# Get IPs
	query='//NIC/IP/text()'
	ipAddresses=()
	while IFS= read -r entry; do
	  ipAddresses+=( "$entry" )
	done < <(onevm show $VM_ID -x | xmlstarlet sel -t -v "$query" -n)

	# Wait 25 seconds befor first test
	sleep 80

	# Send sigstop to cloud-init
	# No need for this step if context script does not contain reboot command
	#logging "[$TEMPLATE_IDENTIFIER] DEBUG: Send SIGSTOP to cloud-init."
	#ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$ip_address_for_ssh 'kill -SIGSTOP `pgrep cloud-init`'
	#
	#CLOUD_INIT_PROCESS_STATUS=$(ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" root@$ip_address_for_ssh 'ps cax | grep cloud-init')
	#CLOUD_INIT_PROCESS_STATUS=$(echo $CLOUD_INIT_PROCESS_STATUS | awk '{print $3}')
	#
	#if [ "$CLOUD_INIT_PROCESS_STATUS" == "T" ]; then
	#	logging "[$TEMPLATE_IDENTIFIER] DEBUG: Process cloud-init successfully stopped."
	#	else
	#	logging "[$TEMPLATE_IDENTIFIER] DEBUG: Process cloud-init still running."
	#fi

	echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> $FOLDER_TO_SAVE_REPORTS/report
	echo "<SECANT>" >> $FOLDER_TO_SAVE_REPORTS/report

	#Run external tests
	logging "[$TEMPLATE_IDENTIFIER] INFO: Starting external tests..."
	for filename in $EXTERNAL_TESTS_FOLDER_PATH/*/
	do
	 (cd $filename && ./main.sh ${ipAddresses[0]} $VM_ID $TEMPLATE_IDENTIFIER $FOLDER_TO_SAVE_REPORTS >> $FOLDER_TO_SAVE_REPORTS/report)
	done

	number_of_attempts=0
	while [ -z "$ip_address_for_ssh" ] && [ $number_of_attempts -lt 15 ]
	do
		ip_address_for_ssh=""
		for ip in "${ipAddresses[@]}"
		do
			ssh_state=$(nmap $ip -PN -p ssh | egrep -o 'open|closed|filtered')
			if [ "$ssh_state" == "open" ]; then
				logging "[$TEMPLATE_IDENTIFIER] INFO: Open SSH port has been successfully detected, IP address: $ip"
				ip_address_for_ssh=$ip
				break;
			fi
		done

		if [ -z "$ip_address_for_ssh" ]; then
			((number_of_attempts++))
			sleep 5s
		fi
	done

	#Run internal tests
	if [ -z "$ip_address_for_ssh" ]; then
		logging "[$TEMPLATE_IDENTIFIER] ERROR: Open SSH port has not been detected."
		onevm delete $VM_ID
		#exit 1
	else
		logging "[$TEMPLATE_IDENTIFIER] INFO: Starting internal tests..."
		for filename in $INTERNAL_TESTS_FOLDER_PATH/*/
		do
			(cd $filename && ./main.sh $ip_address_for_ssh $VM_ID $TEMPLATE_IDENTIFIER $FOLDER_TO_SAVE_REPORTS >> $FOLDER_TO_SAVE_REPORTS/report)
		done
	fi

	echo "</SECANT>" >> $FOLDER_TO_SAVE_REPORTS/report

	# Remove white lines from file
	sed '/^$/d' $FOLDER_TO_SAVE_REPORTS/report > $FOLDER_TO_SAVE_REPORTS/report.xml
	rm -f $FOLDER_TO_SAVE_REPORTS/report

	echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> $FOLDER_TO_SAVE_REPORTS/assessment_result.xml
	if [[ "$CURRENT_DIRECTORY" == "lib" ]] ; then
		python assessment.py $TEMPLATE_ID $FOLDER_TO_SAVE_REPORTS/report.xml >> $FOLDER_TO_SAVE_REPORTS/assessment_result.xml
	else
		python lib/assessment.py $TEMPLATE_ID $FOLDER_TO_SAVE_REPORTS/report.xml >> $FOLDER_TO_SAVE_REPORTS/assessment_result.xml
	fi


	logging "[$TEMPLATE_IDENTIFIER] INFO: Delete Virtual Machine $VM_ID."
	#onevm delete $VM_ID
	onevm shutdown --hard $VM_ID

#	if $RUN_WITH_CONTEXT_SCRIPT; then
#		delete_template_and_images $TEMPLATE_ID
#	fi
done



