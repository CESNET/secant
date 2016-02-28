#!/usr/bin/env bash

cd /tmp/lynis

REPORT_LOCATION='/var/log/lynis-report.dat'

./lynis -c --cronjob > /dev/null

if [ -f $REPORT_LOCATION ];
then
   grep 'Warning\|Suggestion' /var/log/lynis.log
else
   echo "Error: Missing Lynis report"
fi