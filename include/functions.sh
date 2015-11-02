#!/usr/bin/env bash
source secant.conf

logging() { echo `date +"%Y-%d-%m %H:%M:%S"` "$*" >> $log_file; }
