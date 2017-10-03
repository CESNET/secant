import re, sys, os
from lxml import etree
import ConfigParser

settings = ConfigParser.ConfigParser()
settings.read(os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'assessment.conf')

def evaluateReport(report_file):
    alerts = []
    report = etree.parse(report_file)
    find_text = etree.XPath("/SECANT/SSH_AUTH_TEST/text()")

    try:
        ssh_test_result =  find_text(report)[0]
    except (ValueError,IndexError):
        return alerts

    regex = re.search('is\sallowed', ssh_test_result)
    if regex:
        alerts.append(ssh_test_result)
    return alerts
