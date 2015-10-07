#!/usr/bin/env bash

cd /tmp/Lynis
REPORT_LOCATION='/var/log/lynis-report.dat'
echo [`date +"%T"`] "### Lynis Report ###"
echo [`date +"%T"`] "===---------------------------------------------------------------==="

while ./lynis --quiet -Q > /dev/null; do sleep 1; done

if [ -f $REPORT_LOCATION ];
then
   #echo `grep 'Warning' /var/log/lynis.log`
   #echo `grep 'Suggestion' /var/log/lynis.log`
   grep 'Warning' /var/log/lynis.log
   grep 'Suggestion' /var/log/lynis.log

else
   echo [`date +"%T"`] "[ERROR] Missing Lynis report"
fi

echo [`date +"%T"`] "===---------------------------------------------------------------==="
