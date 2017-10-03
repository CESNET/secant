from lxml import etree
import ConfigParser, os

settings = ConfigParser.ConfigParser()
settings.read(os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'assessment.conf')

def evaluateReport(report_file):
    alerts = []
    report = etree.parse(report_file)
    find_text = etree.XPath( "/SECANT/PAKITI_TEST/PKG/text()")
    pkgs = find_text(report)
    if pkgs:
        for pkg in pkgs:
            alerts.append("Vulnerable package: " + pkg)
    return alerts
