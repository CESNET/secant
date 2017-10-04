from lxml import etree
import ConfigParser, os, re

settings = ConfigParser.ConfigParser()
settings.read(os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'assessment.conf')

def evaluateReport(report_file):
    alerts = []
    report = etree.parse(report_file)
    find_text = etree.XPath("/SECANT/NTP_AMPLIFICATION_TEST/text()")

    try:
        ntp_amplitication_test_result =  find_text(report)[0]
    except (ValueError,IndexError):
        return alerts

    regex = re.search('is\senable', ntp_amplitication_test_result)
    if regex:
        alerts.append(ntp_amplitication_test_result)
    return alerts
