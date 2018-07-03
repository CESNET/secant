#!/usr/bin/python

from __future__ import print_function

from lxml import etree
import xml.etree.ElementTree as ET
import sys

tree = etree.parse(sys.stdin)

cmd = tree.getroot().get("args")

hosts = tree.findall("host")
if (len(hosts)) != 1:
    print("No host reported by nmap", file=sys.stderr)
    exit(1)

host = hosts[0]

host_state = host.find("status").get("state")

ports = []
for port in host.find("ports").findall("port"):
    state = port.find("state").get("state")
    if state != "open":
        continue
    ports.append("%s/%s" % (port.get("portid"), port.get("protocol")))

print ("Host is %s" % host_state)
print ("Host probed using: %s" % cmd)
if len(ports) == 0:
    print ("No open port detected")
else:
    print("The VM was found to expose one or more services")
    print("Open ports detected:")
    print(",".join(ports))
