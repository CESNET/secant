import re
import sys
import fileinput
from lxml import etree
import ConfigParser
import os
import importlib
import logging

external_tests_path=""
internal_tests_path=""
if os.path.split(os.getcwd())[-1] == 'lib':
    sys.path.append('../include')
    external_tests_path="../external_tests"
    internal_tests_path="../internal_tests"
else:
    sys.path.append('include')
    external_tests_path="external_tests"
    internal_tests_path="internal_tests"

import py_functions

py_functions.setLogging()

def assessment(template_id, report_file):
    alerts = []
    for dir_name in os.listdir(external_tests_path):
            path = external_tests_path + "/" + dir_name
            print path
            sys.path.append(path)
            mod = importlib.import_module(dir_name)
            alerts = alerts + mod.evaluateReport(report_file)

    for dir_name in os.listdir(internal_tests_path):
            path = internal_tests_path + "/" + dir_name
            print path
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