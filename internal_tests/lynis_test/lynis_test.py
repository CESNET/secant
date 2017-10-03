import re
from lxml import etree
import ConfigParser, os

settings = ConfigParser.ConfigParser()

settings.read(os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'assessment.conf')

def evaluateReport(report_file):
    alerts = []
    report = etree.parse(report_file)

    warnings = settings.get('LYNIS_TEST', 'Warnings').split(', ')
    if not (len(warnings) == 1 and warnings[0] == ''):
        for warning in warnings:
            find_text = etree.XPath( "/SECANT/LYNIS_TEST/WARNINGS/" + warning + "/text()")
            if find_text(report):
                alerts.append(find_text(report)[0])

    suggestions = settings.get('LYNIS_TEST', 'Suggestions').split(', ')
    if not (len(suggestions) == 1 and suggestions[0] == ''):
        for suggestion in suggestions:
            find_text = etree.XPath( "//SECANT/LYNIS_TEST/SUGGESTIONS/" + suggestion + "/text()")
            if find_text(report):
                alerts.append(find_text(report)[0])
    return alerts
