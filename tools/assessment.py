#!/usr/bin/env python3

import re
import sys
import fileinput
from lxml import etree
import os
import importlib
import time
import logging
import yaml
import subprocess

dirname = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, dirname+'/../include/')
probes_path='/../probes/'
from py_functions import getSettingsFromBashConfFile

def assessment(template_id, report_file, tests_version, base_mpuri, message_id):
    total_outcome = False
    secant =  etree.Element('SECANT')
    version = etree.SubElement(secant, "VERSION")
    imageID = etree.SubElement(secant, "IMAGEID")
    date = etree.SubElement(secant, "DATE")
    outcome = etree.SubElement(secant, "OUTCOME")
    outcome_description = etree.SubElement(secant, "OUTCOME_DESCRIPTION")
    messageID = etree.SubElement(secant, "MESSAGEID")
    log = etree.SubElement(secant, "LOG")
    version.text = tests_version
    imageID.text = base_mpuri
    messageID.text = message_id
    report = etree.parse(report_file)
    conf_path = os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'secant.conf'

    total_outcomeE = False
    total_outcomeI = False
    config = getSettingsFromBashConfFile(conf_path, 'SECANT_PROBES').split(',')
    for probe_name in config:
        if report.find(probe_name) is not None:
            check = etree.SubElement(log, "CHECK")
            test_version = etree.SubElement(check, "VERSION")
            test_id = etree.SubElement(check, "TEST_ID")
            description = etree.SubElement(check, "DESCRIPTION")
            test_outcome = etree.SubElement(check, "OUTCOME")
            summary = etree.SubElement(check, "SUMMARY")
            details = etree.SubElement(check, "DETAILS")
            test_id.text = probe_name.upper()

            with open(dirname+'/../probes/'+probe_name+'/probe.yaml') as y:
                data = yaml.load(y)
            test_version.text = str(data['version'])
            description.text = data['title']

            status = report.find(probe_name).get("status")
            test_outcome.text = status

            if (status == "ERROR"):
                total_outcomeE = True
            if (status == "INTERNAL_FAILURE"):
                total_outcomeI = True

            nodeS = report.find("/" + probe_name + "/summary")
            if nodeS is not None:
                summary.text = nodeS.text

            nodeD = report.find("/" + probe_name + "/details")
            if nodeD is not None:
                if nodeD.text == '\n\t':
                    details.text = None
                else:
                    details.text = nodeD.text
        else:
            raise Exception('Probe result of %s not found in report.' % (probe_name))

    if total_outcomeI:
        outcome.text = 'INTERNAL_FAILURE'
        outcome_description.text = 'Test finished unsuccessfully due to internal failure.'
    elif total_outcomeE:
        outcome.text = 'FAIL'
        outcome_description.text = 'Test finished successfully. Machine is exposed to attacks.'
    else:
        outcome.text = "OK"
        outcome_description.text = 'Test finished successfully. Machine is not exposed to attacks.'

    date.text = str(time.time())
    # etree should output the XML declaration itself
    print("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    print(etree.tostring(secant,pretty_print=True).decode('utf-8'))

if __name__ == "__main__":
    assessment(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
