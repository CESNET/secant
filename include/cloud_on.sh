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
    logging $TEMPLATE_IDENTIFIER "Shutting down VM $VM_ID." "DEBUG"
    onevm shutdown --hard $VM_ID
    if [ $? -ne 0 ]; then
        logging $TEMPLATE_IDENTIFIER "Failed to shutdown VM $VM_ID." "ERROR"
        return 1
    fi
}

cloud_get_vm_ids()
{
    IDS=$(onevm list)
    if [ $? -ne 0 ]; then
        logging "Failed to get list of vms ids." "ERROR"
        return 1
    fi
    awk '{ print $1 }' <<< "$IDS" | sed '1d'
}

cloud_get_template_ids()
{
    IDS=$(onetemplate list)
    if [ $? -ne 0 ]; then
        logging "Failed to get list of templates ids." "ERROR"
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
        logging "Failed to query $QUERY on vm with id $ID." "ERROR"
        return 1
    fi
    xmlstarlet sel -t -v $QUERY -n <<< "$CLOUD_QUERY"
}

cloud_template_query()
{
    ID=$1
    QUERY=$2
    CLOUD_QUERY=$(onetemplate show $ID -x)
    if [ $? -ne 0 ]; then
        logging "Failed to query $QUERY on template with id $ID." "ERROR"
        return 1
    fi
    xmlstarlet sel -t -v $QUERY -n <<< "$CLOUD_QUERY"
}

cloud_start_vm()
{
    ID=$1
    CTX=$2
    CLOUD_START_VM=$(onetemplate instantiate $ID $CTX)
    if [ $? -ne 0 ]; then
        logging "Failed instantiate template $ID." "ERROR"
        return 1
    fi
    echo $CLOUD_START_VM
}

cloud_delete_template()
{
    ID=$1
    CLOUD_DELETE_TEMPLATE=$(onetemplate delete $ID)
    if [ $? -ne 0 ]; then
        logging "Failed to delete template $ID." "ERROR"
        return 1
    fi
    echo $CLOUD_DELETE_TEMPLATE
}

cloud_delete_image()
{
    IMAGE_NAME=$1
    CLOUD_DELETE_IMAGE=$(oneimage delete $IMAGE_NAME)
    if [ $? -ne 0 ]; then
        logging "Failed to delete image $IMAGE_NAME." "ERROR"
        return 1
    fi
    echo $CLOUD_DELETE_IMAGE
}
