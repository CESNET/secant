#!/bin/bash

VM_IP=$1
FOLDER_PATH=$2
TEMPLATE_IDENTIFIER=$3

BASE=$(dirname $0)
CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
source ${CONFIG_DIR}/probes.conf
source $BASE/../../include/functions.sh

if [[ $# -eq 0 ]] ; then
    echo 'No input arguments'
    exit 1
fi

remote_exec "$VM_IP" "$LOGIN_AS_USER" "perl - --site=SECANT" "$SECANT_PROBE_PAKITI_CLIENT" "$FOLDER_PATH/pakiti_test-pkgs.txt" 2>$FOLDER_PATH/pakiti.stderr
if [ $? -ne 0 ]; then
    echo "Pakiti client failed to get a list of installed packages from the VM" >&2
    cat $FOLDER_PATH/pakiti.stderr >&2
    exit 1
fi

$SECANT_PROBE_PAKITI_CLIENT --url "$SECANT_PROBE_PAKITI_URL" --mode=store-and-report --host "$TEMPLATE_IDENTIFIER" --input $FOLDER_PATH/pakiti_test-pkgs.txt > $FOLDER_PATH/pakiti_test-result.txt 2>$FOLDER_PATH/pakiti_test-result.stderr
if [ $? -ne 0 ]; then
    echo "Pakiti test failed while sending data to the Pakiti server" >&2
    cat $FOLDER_PATH/pakiti_test-result.stderr >&2
    exit 1
fi

lines=$(grep -vx OK $FOLDER_PATH/pakiti_test-result.txt | wc -l)
if [ $lines -eq 0 ]; then
    echo OK
    echo "No tagged vulnerabilities found by Pakiti"
    exit 0
fi

echo ERROR
echo "Pakiti detected vulnerable packages"
grep -vx OK $FOLDER_PATH/pakiti_test-result.txt
