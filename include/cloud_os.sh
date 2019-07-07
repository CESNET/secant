#!/usr/bin/env bash
cloud_init()
{
    # only ON is supported atm
    CONFIG_DIR=${SECANT_CONFIG_DIR:-/etc/secant}
    source ${CONFIG_DIR}/cloud.conf

    export ONE_HOST ONE_XMLRPC
}

#ok
cloud_shutdown_vm()
{
    VM_ID=$1
    openstack server delete $VM_ID
    if [ $? -ne 0 ]; then
        return 1
    fi
}

#grep
cloud_get_vm_ids()
{
    IDS=$(openstack server list -f json | jq -r '.[].ID')
    if [ $? -ne 0 ]; then
        return 1
    fi
}

cloud_get_template_ids()
{
    IDS=$(openstack image list -f json | jq -r '.[].ID')
    if [ $? -ne 0 ]; then
        return 1
    fi
}

cloud_vm_query()
{
    ID=$1
    QUERY=$2
    CLOUD_QUERY=$(openstack server show $ID)
    if [ $? -ne 0 ]; then
        return 1
    fi
    VM_RESULT=$("$CLOUD_QUERY" | jq -r '.$QUERY')
    if [ -z "$VM_RESULT" ]; then
        return 1
    fi
    printf "$VM_RESULT"
}

cloud_template_query()
{
    ID=$1
    QUERY=$2
    CLOUD_QUERY=$(openstack image show $ID)
    if [ $? -ne 0 ]; then
        return 1
    fi
    TEMP_RESULT=$("$CLOUD_QUERY" | jq -r '.$QUERY')
    if [ -z "$TEMP_RESULT" ]; then
        return 1
    fi
    printf "$TEMP_RESULT"
}

cloud_start_vm()
{
    ID=$1
    CTX=$2
    CLOUD_START_VM=$(openstack create "VM" --key-name Secant --security-groups Secant --flavor m1.small --image $ID --nic net-id="ROUTER" --user-data $CTX)
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo $CLOUD_START_VM
}

cloud_delete_template()
{
    ID=$1
    CLOUD_DELETE_TEMPLATE=$(openstack image delete $ID)
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo $CLOUD_DELETE_TEMPLATE
}
