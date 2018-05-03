#!/usr/bin/env bash

clean_if_analysis_failed() {
    VM_IDS=($(onevm list | awk '{ print $1 }' | sed '1d'))
    for VM_ID in "${VM_IDS[@]}"
    do
        query='//NIFTY_APPLIANCE_ID'
        NIFTY_ID=$(onevm show $VM_ID -x | xmlstarlet sel -t -v "$query")
        if [ -n "$NIFTY_ID" ]; then # n - for not empty
            if [[ $NIFTY_ID == $1 ]]; then
                onevm shutdown $VM_ID --hard
            fi
        fi
    done
}

delete_template_and_images(){
	# Get Template Images
	query='//DISK/IMAGE/text()'
	images=()
	while IFS= read -r entry; do
	  images+=( "$entry" )
	done < <(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "$query" -n)

	for image_name in "${images[@]}"
	do
	    DELETE_IMAGE_RESULT=$(oneimage delete "$image_name")
	    if [[ ! -n  $DELETE_IMAGE_RESULT ]]
	    then
	        logging $TEMPLATE_IDENTIFIER "Image: $image_name successfully deleted." "DEBUG"
	    else
            CHECK_FOR_IMAGE_MANAGE_ERROR=$(echo $DELETE_IMAGE_RESULT | grep -o "Not authorized to perform MANAGE IMAGE \[.[0-9]*\]")
            if [[ -n $CHECK_FOR_IMAGE_MANAGE_ERROR ]]
            then
                logging $TEMPLATE_IDENTIFIER "Secant user is not authorized to delete image: $(echo $CHECK_FOR_IMAGE_MANAGE_ERROR | grep -o '[0-9]*')." "ERROR"
            fi
        fi
	done

    DELETE_TEMPLATE_RESULT=$(onetemplate delete $TEMPLATE_ID)
    if [[ ! -n  $DELETE_TEMPLATE_RESULT ]]
	then
	    logging $TEMPLATE_IDENTIFIER "Template: $TEMPLATE_ID successfully deleted." "DEBUG"
    else
        CHECK_FOR_TEMPLATE_MANAGE_ERROR=$(echo $DELETE_TEMPLATE_RESULT | grep -o "Not authorized to perform MANAGE TEMPLATE \[.[0-9]*\]")
        if [[ -n $CHECK_FOR_TEMPLATE_MANAGE_ERROR ]]
        then
            logging $TEMPLATE_IDENTIFIER "Secant user is not authorized to delete template: $(echo $CHECK_FOR_TEMPLATE_MANAGE_ERROR | grep -o '[0-9]*')." "ERROR"
        fi
    fi
}

usage()
{
    print_ascii_art
    echo "usage: $0 [-ht] [-d directory]"
}

CURRENT_DIRECTORY=${PWD##*/}
if [[ "$CURRENT_DIRECTORY" != "secant" ]] ; then
	echo `date +"%Y-%d-%m %H:%M:%S"` "[SECANT] ERROR: Please run Secant from the secant directory."
	exit 0
fi

source include/functions.sh

TEST_RUN="no"

CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}

source ${CONFIG_DIR}/secant.conf

while [[ $# -gt 0 ]]; do
    case "$1" in
    -d|--report-dir)
        REPORT_DIR="$2"
        shift
        shift
        ;;
    -h|--help)
        usage
        exit 0
        shift
        ;;
    -t|--test-run)
        TEST_RUN="yes"
        shift
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done

[ "$TEST_RUN" = "yes" ] && DELETE_TEMPLATES="no"
[ -z "$REPORT_DIR" ] && REPORT_DIR="$STATE_DIR/reports"


logging "SECANT" "Starting" "INFO"

# Generate user tocken
#export ONE_XMLRPC=$ONE_XMLRPC
#oneuser login secant --cert $CERT_PATH --key $KEY_PATH --x509 --force >/dev/null 2>&1

#TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed -n "$TEMPLATE_NUMBER,$TEMPLATE_NUMBER p")) # Get first 5 templates ids
#TEMPLATES=($(onetemplate list | awk '{ print $1 }' | sed -n "70,70p")) # Get first 5 templates ids

onetemplate list > /tmp/templates.$$
ret=$?
trap "rm -f /tmp/templates.$$" EXIT
if [ $ret -ne 0 ]; then
    logging "SECANT" "Failed to retrieve templates (check authentication)" "ERROR"
    exit 1
fi
TEMPLATES=($(awk '{ print $1 }' /tmp/templates.$$ | sed '1d'))

query='//CLOUDKEEPER_APPLIANCE_MPURI' # attribute which determines that template should be analyzed
#query='//VMCATCHER_EVENT_DC_IDENTIFIER'
TEMPLATES_FOR_ANALYSIS=()
for TEMPLATE_ID in "${TEMPLATES[@]}"
do
    NIFTY_ID=$(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "$query")
    if [ -n "$NIFTY_ID" ]; then # n - for not empty
        TEMPLATES_FOR_ANALYSIS+=($TEMPLATE_ID)
    fi
done

if [ ${#TEMPLATES_FOR_ANALYSIS[@]} -eq 0 ]; then
    logging "SECANT" "No templates for analysis." "INFO"
    exit 0
fi

for TEMPLATE_ID in "${TEMPLATES_FOR_ANALYSIS[@]}"; do
    if [[ $TEMPLATE_ID =~ ^[0-9]+$ ]] ; then
        #TEMPLATE_IDENTIFIER=$TEMPLATE_ID
        TEMPLATE_IDENTIFIER=$(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "//CLOUDKEEPER_APPLIANCE_ID")
        #TEMPLATE_IDENTIFIER=$(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v "//VMCATCHER_EVENT_DC_IDENTIFIER")
        BASE_MPURI=$(onetemplate show $TEMPLATE_ID -x | xmlstarlet sel -t -v '//CLOUDKEEPER_APPLIANCE_ATTRIBUTES' | base64 -d | jq '.["ad:base_mpuri"]'|sed -e '1,$s/"//g')
        (
            FOLDER_PATH=$REPORT_DIR/$TEMPLATE_IDENTIFIER
            if [[ -d $FOLDER_PATH ]] ; then
                i=1
                while [[ -d $FOLDER_PATH-$i ]]; do
                    let i++
                done
                FOLDER_PATH=$FOLDER_PATH-$i
            fi
            mkdir -p "$FOLDER_PATH" || exit 1

            logging $TEMPLATE_IDENTIFIER "Starting analysis (BASE_MPURI = $BASE_MPURI) template_id == $TEMPLATE_ID." "INFO"
            analyse_template "$TEMPLATE_ID" "$TEMPLATE_IDENTIFIER" "$BASE_MPURI" "$FOLDER_PATH" > ${FOLDER_PATH}/analysis_output.stdout 2>${FOLDER_PATH}/analysis_output.stderr
            if [ $? -ne 0 ]; then
                logging "$TEMPLATE_ID" "Analysis finished with errors (BASE_MPURI = $BASE_MPURI)." "ERROR"
                clean_if_analysis_failed $TEMPLATE_IDENTIFIER
                exit 1
            fi

            logging $TEMPLATE_IDENTIFIER "Analysis completed successfully (BASE_MPURI = $BASE_MPURI), check ${FOLDER_PATH}/analysis_output.{stdout,stderr} for artifacts." "INFO"

            # Remove white lines from file
            sed '/^$/d' $FOLDER_TO_SAVE_REPORTS/report > $FOLDER_TO_SAVE_REPORTS/report.xml
            rm -f $FOLDER_TO_SAVE_REPORTS/report

            if [[ "$CURRENT_DIRECTORY" == "lib" ]] ; then
                python assessment.py "$TEMPLATE_IDENTIFIER" "$FOLDER_TO_SAVE_REPORTS/report.xml" "$VERSION" "$BASE_MPURI" >> $FOLDER_PATH/assessment_result.xml
            else
                python lib/assessment.py "$TEMPLATE_IDENTIFIER" "$FOLDER_TO_SAVE_REPORTS/report.xml" "$VERSION" "$BASE_MPURI" >> $FOLDER_PATH/assessment_result.xml
            fi

            [ "$DELETE_TEMPLATES" = "yes" ] && delete_template_and_images $TEMPLATE_ID
            [ "$TEST_RUN" = "yes" ] || python ./lib/argo_communicator.py --mode push --niftyID $TEMPLATE_IDENTIFIER --path $FOLDER_PATH/assessment_result.xml --base_mpuri $BASE_MPURI
        ) &
    fi
done

wait
