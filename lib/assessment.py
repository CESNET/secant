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
secant_settings = ConfigParser.ConfigParser()
if os.path.split(os.getcwd())[-1] == 'lib':
    sys.path.append('../include')
    assessment_settings.read('../conf/assessment.conf')
    #secant_settings.read('../conf/secant.conf')
    external_tests_path="../external_tests"
    internal_tests_path="../internal_tests"
else:
    sys.path.append('include')
    assessment_settings.read('conf/assessment.conf')
    #secant_settings.read('conf/secant.conf')
    external_tests_path="external_tests"
    internal_tests_path="internal_tests"

import py_functions

py_functions.setLogging()

def assessment(template_id, report_file, tests_version):
    total_outcome = False
    secant =  etree.Element('SECANT')
    version = etree.SubElement(secant, "VERSION")
    imageID = etree.SubElement(secant, "IMAGEID")
    date = etree.SubElement(secant, "DATE")
    outcome = etree.SubElement(secant, "OUTCOME")
    log = etree.SubElement(secant, "LOG")
    version.text = tests_version
    imageID.text = template_id

    for tests_type in (external_tests_path, internal_tests_path):
        for dir_name in os.listdir(tests_type):
            check = etree.SubElement(log, "CHECK")
            test_version = etree.SubElement(check, "VERSION")
            test_id = etree.SubElement(check, "TEST_ID")
            description = etree.SubElement(check, "DESCRIPTION")
            test_outcome = etree.SubElement(check, "OUTCOME")
            test_id.text = dir_name.upper()
            test_version.text = assessment_settings.get(dir_name.upper(), 'Version')
            description.text = assessment_settings.get(dir_name.upper(), 'Description')

            path = tests_type + "/" + dir_name
            sys.path.append(path)
            mod = importlib.import_module(dir_name)
            fail_details = etree.SubElement(check, "DETAILS")

            test_running_status = py_functions.check_if_test_completed_successfully(test_id.text, report_file)
            if test_running_status:
                test_outcome.text = "NA"
                fail_details.text = test_running_status[0]
            else:
                fail_details.text = ';'.join(map(str, mod.evaluateReport(report_file)))
                if fail_details.text:
                    test_outcome.text = "FAIL"
                    total_outcome = True
                else:
                    test_outcome.text = "OK"

    if total_outcome:
        outcome.text = "FAIL"
    else:
        outcome.text = "OK"

    date.text = str(time.time())
    logging.debug('[%s] %s: Assessment completed', template_id, 'DEBUG')
    print etree.tostring(secant,pretty_print=True)

if __name__ == "__main__":
   assessment(sys.argv[1], sys.argv[2], sys.argv[3])