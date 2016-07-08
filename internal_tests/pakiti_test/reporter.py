import re, sys, os, fileinput, logging
from lxml import etree

template_id = sys.argv[1]
# if os.path.split(os.getcwd())[-1] == 'lib':
#     sys.path.append('../include/')
# else:
#     if os.path.split(os.getcwd())[-1] == 'secant':
#         sys.path.append('include/')
#
# import py_functions

sys.path.append('../../include/')
import py_functions

py_functions.setLogging()
logging.debug('[%s] %s: Start PAKITI_TEST reporter.', template_id, 'DEBUG')

pakiti =  etree.Element('PAKITI_TEST')

pakiti_status = sys.stdin.readline()

if pakiti_status == 'ERROR':
    error = etree.SubElement(pakiti, "ERROR")
    error.text = "Pakiti error appears during data processing."
else:
    pkg_count = 0
    for line in sys.stdin.readlines():
        pkg_count += 1
        pkg_list = re.split('\s+', line)
        pkg = etree.SubElement(pakiti, "PKG")
        pkg.text = pkg_list[0] + ", " + pkg_list[1] + ", " + pkg_list[2]
        # name = etree.SubElement(pkg, "NAME")
        # name.text = pkg_list[0]
        # version = etree.SubElement(pkg, "VERSION")
        # version.text = pkg_list[1]
        # arch = etree.SubElement(pkg, "ARCH")
        # arch.text = pkg_list[2]

    if pkg_count == 0:
        pakiti.text = "No vulnerable packages."

print etree.tostring(pakiti,pretty_print=True)


