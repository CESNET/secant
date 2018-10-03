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
            split = line.strip().split('=', 1)
            if len(split) == 2:
                config[split[0]] = split[1]
    return config[key]

def setLogging():
    logfile = getSettingsFromBashConfFile('/etc/secant/secant.conf', "log_file")

    logging.basicConfig(format='%(asctime)s [%(filename)s] %(levelname)s: %(message)s', filename=logfile,level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S')

    console = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s [%(filename)s] %(levelname)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
    console.setFormatter(formatter)
    console.setLevel(logging.ERROR)
    if len(logging.getLogger('').handlers) == 1:
         logging.getLogger('').addHandler(console)
