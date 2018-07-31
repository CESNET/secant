import yaml
import sys
import os
from lxml import etree

def open_ports(folder_result, portid, protocol):
    dirname = os.path.dirname(os.path.realpath(__file__))
    with open(dirname+'/../open_ports/probe.yaml') as y:
        data = yaml.load(y)

    parsed = etree.parse(folder_result+'/'+data['output'])
    for port in parsed.findall('.//port'):
        if (str(port.get('portid')) == str(portid) and port.get('protocol') == protocol and port.find('state').get('state') == 'open'): return True
    return False
