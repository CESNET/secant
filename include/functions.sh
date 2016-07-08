#!/usr/bin/env bash
# $1 : secant conf file path

#DEFAULT_SECANT_CONF_PATH=../../conf/secant.conf
#SECANT_CONF_PATH=${1-$DEFAULT_SECANT_CONF_PATH}
#source "$SECANT_CONF_PATH"

CURRENT_DIRECTORY=${PWD##*/}
if [[ "$CURRENT_DIRECTORY" == "lib" ]] ; then
    source ../conf/secant.conf
else
    if [[ "$CURRENT_DIRECTORY" == "secant" ]] ; then
        source conf/secant.conf
    else
        source ../../conf/secant.conf
    fi
fi



logging() {
    if [ $3 == "INFO" ]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] INFO: $2" >> $log_file;
    fi

    if [ $3 == "ERROR" ]; then
        echo `date +"%Y-%d-%m %H:%M:%S"` "[$1] ERROR: $2" >> $log_file;
    fi

    if [ $3 == "DEBUG" ] && [ $DEBUG = true ]; then
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
