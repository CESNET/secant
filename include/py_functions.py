import logging
import errno,sys,os,re, mmap
from lxml import etree

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
    with open(config_file) as f:
        config = {}
        for line in f:
            split = line.strip().split(sep='=', maxsplit=1)
            if len(split) == 2:
                config[split[0]] = split[1]
    return config[key]

def setLogging():
    secant_conf_path = os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'secant.conf'

    debug = ""
    with open(secant_conf_path, 'r') as f:
        data = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        mo = re.search(r'(DEBUG)=((true\b)|(false\b))', data)
        if mo:
            debug = mo.group(2)

    log_level = logging.DEBUG

    if debug == "false":
        log_level = logging.INFO

    logging.basicConfig(format='%(asctime)s %(message)s', filename=getSettingsFromBashConfFile(secant_conf_path, 'log_file'),level=log_level, datefmt='%Y-%m-%d %H:%M:%S')
