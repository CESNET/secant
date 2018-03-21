import re
from lxml import etree
import sys

template_id = sys.argv[1]
ssh_auth_test =  etree.Element('SSH_AUTH_TEST')

if len(sys.argv) == 3:
    if sys.argv[2] == 'FAIL':
        ssh_auth_test.set('status', 'FAIL')
    elif sys.argv[2] == 'SKIP':
        ssh_auth_test.set('status', 'SKIP')
else:
    r = re.compile('Permission\sdenied\s.*')
    login_reply = filter(r.match, sys.stdin.readlines())[0]
    regex = re.search('Permission\sdenied\s[(][a-z,-]+[,]password[a-z,)].*', login_reply)
    if regex:
        ssh_auth_test.text = "SSH password authentication is allowed"
    else:
        regex = re.search('SSH port reported as filtered', login_reply)
        if regex:
            ssh_auth_test.text = regex.group(0)
        else:
            ssh_auth_test.text = "SSH password authentication is not allowed"

if 'status' not in ssh_auth_test.attrib:
    ssh_auth_test.set('status', 'OK')
print etree.tostring(ssh_auth_test,pretty_print=True)

