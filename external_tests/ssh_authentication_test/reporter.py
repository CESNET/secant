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
#allowed = False
stdout_data = sys.stdin.readlines()

for line in stdout_data:
    regex = re.search('Permission\sdenied\s[(][a-z,-]+[,]password[a-z,)].*', line)
    if regex:
        ssh_auth_test.text = "SSH password authentication is allowed"
        #allowed = True
        break
    else:
        regex = re.search('SSH port reported as filtered', line)
        if regex:
            ssh_auth_test.text = regex.group(0)
            break
        else:
            ssh_auth_test.text = "SSH password authentication is not allowed"
            break

print etree.tostring(ssh_auth_test,pretty_print=True)

