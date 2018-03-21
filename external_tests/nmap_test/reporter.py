import re
import sys
from lxml import etree

template_id = sys.argv[1]

nmap_test = etree.Element('NMAP_TEST')

if len(sys.argv) == 3:
    if sys.argv[2] == 'FAIL':
        nmap_test.set('status', 'FAIL')
    elif sys.argv[2] == 'SKIP':
        nmap_test.set('status', 'SKIP')
else:
    try:
        tree = etree.parse(sys.stdin)
        if tree.findall(".//hosts[@down='1']"):
            ports_element = etree.Element('ports')
            ports_element.text = "Host seems down"
            nmap_test.insert(0, ports_element)
        else:
            ports = tree.findall(".//ports")
            for port in ports:
                nmap_test.insert(0, port)
    except ValueError as e:
        print('[%s] %s: NMAP_TEST reporter failed during parsing: %s.' % (template_id, 'ERROR', str(e)))
        nmap_test.set('status', 'FAIL')
    except:
        print('[%s] %s: NMAP_TEST reporter unexpected error: %s.' % (template_id, 'ERROR', sys.exc_info()[0]))
        nmap_test.set('status', 'FAIL')

if 'status' not in nmap_test.attrib:
    nmap_test.set('status', 'OK')

print etree.tostring(nmap_test,pretty_print=True)
