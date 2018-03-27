#!/usr/bin/python

import sys
from lxml import etree
import xml.etree.ElementTree as ET

tree = etree.parse(sys.stdin)
print ET.tostring(tree.getroot())
