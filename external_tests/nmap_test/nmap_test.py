from lxml import etree
import ConfigParser, os

settings = ConfigParser.ConfigParser()

if os.path.split(os.getcwd())[-1] == 'lib':
    settings.read('../conf/assessment.conf')
else:
    settings.read('conf/assessment.conf')

def evaluateReport(report_file):
    alerts = []
    ports = settings.get('NmapTest', 'Ports').split(', ')
    report = etree.parse(report_file)
    for port in ports:
        find_text = etree.XPath( "/SECANT/NMAP_TEST/ports/port[contains(@portid, " + port + ")]")
        if find_text(report):
            alerts.append("Port " + port + " is open")
    return alerts