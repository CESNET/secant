from lxml import etree
import ConfigParser

settings = ConfigParser.ConfigParser()
settings.read('conf/assessment.conf')

def evaluateReport(report_file):
    alerts = []
    report = etree.parse(report_file)
    find_text = etree.XPath( "/SECANT/PAKITI_TEST/PKG/text()")
    pkgs = find_text(report)
    if pkgs:
        for pkg in pkgs:
            alerts.append("Vulnerable package: " + pkg)
    return alerts