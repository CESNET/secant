#!/usr/bin/env bash

cd /tmp/lynis

REPORT_LOCATION='/var/log/lynis-report.dat'
echo [`date +"%T"`] "### Lynis Report ###"
echo [`date +"%T"`] "===---------------------------------------------------------------==="

./lynis -c --cronjob > /dev/null &
wait $!

if [ -f $REPORT_LOCATION ];
then
   grep 'Warning' /var/log/lynis.log
   grep 'Suggestion' /var/log/lynis.log

else
   echo [`date +"%T"`] "[ERROR] Missing Lynis report"
fi

echo [`date +"%T"`] "===---------------------------------------------------------------==="