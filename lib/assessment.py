import re
import sys
import fileinput
from lxml import etree
import ConfigParser
import os
import importlib
import time
import logging

external_tests_path=""
internal_tests_path=""
assessment_settings = ConfigParser.ConfigParser()
assessment_settings.read(os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'assessment.conf')
secant_settings = ConfigParser.ConfigParser()
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

def assessment(template_id, report_file, tests_version, base_mpuri):
    total_outcome = False
    secant =  etree.Element('SECANT')
    version = etree.SubElement(secant, "VERSION")
    imageID = etree.SubElement(secant, "IMAGEID")
    date = etree.SubElement(secant, "DATE")
    outcome = etree.SubElement(secant, "OUTCOME")
    log = etree.SubElement(secant, "LOG")
    version.text = tests_version
    imageID.text = base_mpuri

    report = etree.parse(report_file)

    for tests_type in (external_tests_path, internal_tests_path):
        for dir_name in os.listdir(tests_type):
            test_name = dir_name.upper()
            if report.find(test_name) is None:
                continue

            check = etree.SubElement(log, "CHECK")
            test_version = etree.SubElement(check, "VERSION")
            test_id = etree.SubElement(check, "TEST_ID")
            description = etree.SubElement(check, "DESCRIPTION")
            test_outcome = etree.SubElement(check, "OUTCOME")
            test_id.text = test_name
            test_version.text = assessment_settings.get(dir_name.upper(), 'Version')
            description.text = assessment_settings.get(dir_name.upper(), 'Description')

            details = etree.SubElement(check, "DETAILS")

            status = report.find(test_name).get("status")
            test_outcome.text = status
            if (status == "ERROR" or status == "INTERNAL_FAILURE"):
                total_outcome = True

            node = report.find("/" + test_name + "/details")
            if node is not None:
                details.text = node.text


    if total_outcome:
        outcome.text = "FAIL"
    else:
        outcome.text = "OK"

    date.text = str(time.time())
    # etree should output the XML declaration itself
    print("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    print etree.tostring(secant,pretty_print=True)

if __name__ == "__main__":
   assessment(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
