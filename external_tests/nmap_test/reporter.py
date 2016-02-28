import re
import fileinput
import sys
from lxml import etree

ssh_auth_test =  etree.Element('NMAP_TEST')
tree = etree.parse(sys.stdin)

ports = tree.findall(".//ports")
for port in ports:
    ssh_auth_test.insert(0, port)

print etree.tostring(ssh_auth_test,pretty_print=True)
