#!/usr/bin/python

import re
import sys

stdout_data = sys.stdin.readlines()
regex = (re.search('remote\saddress\s*port\slocal\saddress\s*count\sm\sver\srstr\savgint\s*lstint', stdout_data[0])) if stdout_data else ""
if regex: 
    print('ERROR')
    print('The machine exposes NTP configuration that can be abused for amplification attacks')
    print('Monlist response is enabled')
    sys.exit(0)
else:
    print('OK')
    print('NTP port on UDP is open')
    print('Monlist response is disabled or not available')
    sys.exit(0)
