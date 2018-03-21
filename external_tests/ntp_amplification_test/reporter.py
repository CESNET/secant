import re
import sys
from lxml import etree

template_id = sys.argv[1]

ntp_amplification_test = etree.Element('NTP_AMPLIFICATION_TEST')

if len(sys.argv) == 3:
    if sys.argv[2] == 'FAIL':
        ntp_amplification_test.set('status', 'FAIL')
    elif sys.argv[2] == 'SKIP':
        ntp_amplification_test.set('status', 'SKIP')
else:
    stdout_data = sys.stdin.readlines()
    #regex = re.search('(?:[0-9]{1,3}\.){3}[0-9]{1,3}: timed out, nothing received', stdout_data[0])
    #print stdout_data[0]
    regex = re.search('remote\saddress\s*port\slocal\saddress\s*count\sm\sver\srstr\savgint\s*lstint', stdout_data[0])
    if regex:
        ntp_amplification_test.text = "Monlist response is enable"
    else:
        ntp_amplification_test.text = "Monlist response is disable"

if 'status' not in ntp_amplification_test.attrib:
    ntp_amplification_test.set('status', 'OK')

print etree.tostring(ntp_amplification_test,pretty_print=True)
