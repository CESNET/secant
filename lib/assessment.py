import re
import sys
import fileinput
from lxml import etree
import ConfigParser
import os
import importlib
import logging
sys.path.append('include')
import py_functions

py_functions.setLogging()

def assessment(template_id, report_file):
    alerts = []
    for dir_name in os.listdir('external_tests'):
            path = "external_tests/" + dir_name
            sys.path.append(path)
            mod = importlib.import_module(dir_name)
            alerts = alerts + mod.evaluateReport(report_file)

    for dir_name in os.listdir('internal_tests'):
            path = "internal_tests/" + dir_name
            sys.path.append(path)
            mod = importlib.import_module(dir_name)
            alerts = alerts + mod.evaluateReport(report_file)

    secant =  etree.Element('SECANT')
    result = etree.SubElement(secant, "RESULT")
    details = etree.SubElement(secant, "DETAILS")

    if alerts:
        result.text = "FAIL"
        delails_string = ""
        for alert in alerts:
            delails_string = delails_string + alert + "\n"
        details.text = delails_string
    else:
        result.text = "OK"
    logging.info('[%s] %s: Assessment complete', template_id, 'INFO')
    print etree.tostring(secant,pretty_print=True)

if __name__ == "__main__":
   assessment(sys.argv[1], sys.argv[2])