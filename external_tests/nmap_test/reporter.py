import re
import fileinput
import sys
from lxml import etree
import logging
sys.path.append('../../include/')
import py_functions


template_id = sys.argv[1]
try:
    py_functions.setLogging()
except IOError as e:
    raise
    sys.exit(1)

logging.debug('[%s] %s: Start NMAP_TEST reporter.', template_id, 'DEBUG')

ssh_auth_test =  etree.Element('NMAP_TEST')
tree = etree.parse(sys.stdin)

ports = tree.findall(".//ports")
for port in ports:
    ssh_auth_test.insert(0, port)

print etree.tostring(ssh_auth_test,pretty_print=True)
