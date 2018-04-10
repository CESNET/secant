#!/usr/bin/python

import re
import sys
from lxml import etree

ntp_amplification_test = etree.Element('NTP_AMPLIFICATION_TEST')

stdout_data = sys.stdin.readlines()
regex = re.search('remote\saddress\s*port\slocal\saddress\s*count\sm\sver\srstr\savgint\s*lstint', stdout_data[0])
if regex:
    ntp_amplification_test.text = "Monlist response is enabled"
    print("ERROR")
else:
    ntp_amplification_test.text = "Monlist response is disabled"
    print("OK")

print (etree.tostring(ntp_amplification_test, pretty_print=True))
