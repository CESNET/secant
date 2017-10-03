#!/usr/bin/env bash
# $1 : secant conf file path

#SECANT_CONF_PATH=${1-$DEFAULT_SECANT_CONF_PATH}
#source "$SECANT_CONF_PATH"

source ${SECANT_CONFIG:-/etc/secant/secant.conf}

logging() {
    if [[ $3 == "INFO" ]]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] INFO: $2" >> $log_file;
    fi

    if [[ $3 == "ERROR" ]]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] ERROR: $2" >> $log_file;
    fi

    if [[ $3 == "DEBUG" ]] && [ $DEBUG = true ]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] DEBUG: $2" >> $log_file;
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
