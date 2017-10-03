import ConfigParser
import logging
import errno,sys,os,re, mmap
from lxml import etree

class FakeSecHead(object):
    def __init__(self, fp):
        self.fp = fp
        self.sechead = '[asection]\n'

    def readline(self):
        if self.sechead:
            try:
                return self.sechead
            finally:
                self.sechead = None
        else:
            return self.fp.readline()

def check_if_test_completed_successfully(test_name, report_file):
    report = etree.parse(report_file)
    status_ok = etree.XPath("//SECANT/" + test_name + "[@status=\"OK\"]")
    status_skip = etree.XPath("//SECANT/" + test_name + "[@status=\"SKIP\"]")
    status_fail = etree.XPath("//SECANT/" + test_name + "[@status=\"FAIL\"]")
    return_str = ''
    if status_ok(report):
        return_str = '' # True, finished successfully withou errors
    elif status_skip(report):
        return_str = 'Test has been skipped due to unsuccessful SSH accesss'
    elif status_fail(report):
        get_text = etree.XPath("text()")
        return_str = get_text(status_fail(report)[0])
    return return_str

def getSettingsFromBashConfFile(config_file, key):
    cp = ConfigParser.SafeConfigParser()
    try:
        cp.readfp(FakeSecHead(open(config_file)))
    except IOError as e:
        raise IOError('Cannot open secant.conf file: ' + os.path.split(os.getcwd())[-1])
    return [x[1] for x in cp.items('asection') if x[0] == key][0]

def setLogging():
    secant_conf_path = os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'secant.conf'

    debug = ""
    with open(secant_conf_path, 'r+') as f:
        data = mmap.mmap(f.fileno(), 0)
        mo = re.search(r'(DEBUG)=((true\b)|(false\b))', data)
        if mo:
            debug = mo.group(2)

    log_level = logging.DEBUG

    if debug == "false":
        log_level = logging.INFO

    logging.basicConfig(format='%(asctime)s %(message)s', filename=getSettingsFromBashConfFile(secant_conf_path, 'log_file'),level=log_level, datefmt='%Y-%m-%d %H:%M:%S')



