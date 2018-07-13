#!/usr/bin/env bash

cd /tmp/lynis

REPORT_LOCATION='/tmp/lynis.txt'

./lynis -c --cronjob --logfile $REPORT_LOCATION > /dev/null

if [ -f $REPORT_LOCATION ];
then
   grep 'Warning\|Suggestion' $REPORT_LOCATION
else
   echo "Error: Missing Lynis report"
fi
