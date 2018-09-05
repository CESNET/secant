#!/usr/bin/env bash

cloud_init()
{
    # only ON is supported atm
    CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
    source ${CONFIG_DIR}/cloud.conf

    export ONE_HOST ONE_XMLRPC
}

cloud_shutdown_vm()
{
    VM_ID=$1
    onevm shutdown --hard $VM_ID
    if [ $? -ne 0 ]; then
        return 1
    fi
}

cloud_get_vm_ids()
{
    IDS=$(onevm list)
    if [ $? -ne 0 ]; then
        return 1
    fi
    awk '{ print $1 }' <<< "$IDS" | sed '1d'
}

cloud_get_template_ids()
{
    IDS=$(onetemplate list)
    if [ $? -ne 0 ]; then
        return 1
    fi
    awk '{ print $1 }' <<< "$IDS" | sed '1d'
}

cloud_vm_query()
{
    ID=$1
    QUERY=$2
    CLOUD_QUERY=$(onevm show $ID -x)
    if [ $? -ne 0 ]; then
        return 1
    fi
    VM_RESULT=$(xmlstarlet sel -t -v $QUERY -n <<< "$CLOUD_QUERY")
    if [ -z "$VM_RESULT" ]; then
        return 1
    fi
    printf "$VM_RESULT"
}

cloud_template_query()
{
    ID=$1
    QUERY=$2
    CLOUD_QUERY=$(onetemplate show $ID -x)
    if [ $? -ne 0 ]; then
        return 1
    fi
    TEMP_RESULT=$(xmlstarlet sel -t -v $QUERY -n <<< "$CLOUD_QUERY")
    if [ -z "$TEMP_RESULT" ]; then
        return 1
    fi
    printf "$TEMP_RESULT"
}

cloud_start_vm()
{
    ID=$1
    CTX=$2
    CLOUD_START_VM=$(onetemplate instantiate $ID $CTX)
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo $CLOUD_START_VM
}

cloud_delete_template()
{
    ID=$1
    CLOUD_DELETE_TEMPLATE=$(onetemplate delete $ID)
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo $CLOUD_DELETE_TEMPLATE
}

cloud_delete_image()
{
    IMAGE_NAME=$1
    CLOUD_DELETE_IMAGE=$(oneimage delete $IMAGE_NAME)
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo $CLOUD_DELETE_IMAGE
}
