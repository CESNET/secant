import re
import fileinput
from lxml import etree
import sys
import logging
sys.path.append('../../include/')
import py_functions

template_id = sys.argv[1]
py_functions.setLogging()
logging.debug('[%s] %s: Start SSH_AUTH_TEST reporter.', template_id, 'DEBUG')
ssh_auth_test =  etree.Element('SSH_AUTH_TEST')

if len(sys.argv) == 3:
    if sys.argv[2] == 'FAIL':
        ssh_auth_test.set('status', 'FAIL')
    elif sys.argv[2] == 'SKIP':
        ssh_auth_test.set('status', 'SKIP')
else:
    stdout_data = sys.stdin.readlines()
    for line in stdout_data:
        regex = re.search('Permission\sdenied\s[(][a-z,-]+[,]password[a-z,)].*', line)
        if regex:
            ssh_auth_test.text = "SSH password authentication is allowed"
            break
        else:
            regex = re.search('SSH port reported as filtered', line)
            if regex:
                ssh_auth_test.text = regex.group(0)
                break
            else:
                ssh_auth_test.text = "SSH password authentication is not allowed"
                break

if 'status' not in ssh_auth_test.attrib:
    ssh_auth_test.set('status', 'OK')
print etree.tostring(ssh_auth_test,pretty_print=True)

