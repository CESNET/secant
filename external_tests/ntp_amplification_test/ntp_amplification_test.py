from lxml import etree
import ConfigParser, os, re

settings = ConfigParser.ConfigParser()
settings.read(os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'assessment.conf'

def evaluateReport(report_file):
    alerts = []
    ports = settings.get('NMAP_TEST', 'Ports').split(', ')
    report = etree.parse(report_file)
    for port in ports:
        find_text = etree.XPath( "/SECANT/NMAP_TEST/ports/port[contains(@portid, " + port + ")]")
        if find_text(report):
            alerts.append("Port " + port + " is open")
    return alerts
