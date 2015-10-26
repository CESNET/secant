#!/usr/bin/env bash

cd /tmp/lynis

REPORT_LOCATION='/var/log/lynis-report.dat'
echo "### Lynis Report ###"
echo "===---------------------------------------------------------------==="

./lynis -c --cronjob > /dev/null

if [ -f $REPORT_LOCATION ];
then
   grep 'Warning' /var/log/lynis.log
   grep 'Suggestion' /var/log/lynis.log

else
   echo "[ERROR] Missing Lynis report"
fi

echo "===---------------------------------------------------------------==="