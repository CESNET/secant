#!/usr/bin/env bash
# $1 : secant conf file path

#SECANT_CONF_PATH=${1-$DEFAULT_SECANT_CONF_PATH}
#source "$SECANT_CONF_PATH"

logging() {
    local log=$log_file
    [ -n "$log" ] || log=/dev/stdout

    if [[ $3 == "INFO" ]]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] INFO: $2" >> $log;
    fi

    if [[ $3 == "ERROR" ]]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] ERROR: $2" >> $log;
    fi

    if [[ $3 == "DEBUG" ]] && [ "$DEBUG" = "true" ]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] DEBUG: $2" >> $log;
    fi
}

print_ascii_art(){
cat << "EOF"
     _______. _______   ______     ___      .__   __. .___________.
    /       ||   ____| /      |   /   \     |  \ |  | |           |
   |   (----`|  |__   |  ,----'  /  ^  \    |   \|  | `---|  |----`
    \   \    |   __|  |  |      /  /_\  \   |  . `  |     |  |
.----)   |   |  |____ |  `----./  _____  \  |  |\   |     |  |
|_______/    |_______| \______/__/     \__\ |__| \__|     |__|
EOF
}

remote_exec()
{
    HOST=$1
    USER=$2
    CMD=$3
    IN=$4
    OUT=$5

    SSH="ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/nulls -o PreferredAuthentications=publickey"

    $SSH ${USER}@${HOST} "$CMD" < $IN > $OUT
    [ $? -eq 0 ] && return 0

    for u in secant centos ubuntu; do
        $SSH ${u}@${HOST} "$CMD" < $IN > $OUT
        [ $? -eq 0 ] && return 0
    done

    return 1
}
