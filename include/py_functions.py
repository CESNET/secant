import ConfigParser
import logging
import errno,sys,os,re, mmap

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

def getSettingsFromBashConfFile(config_file, key):
    cp = ConfigParser.SafeConfigParser()
    try:
        cp.readfp(FakeSecHead(open(config_file)))
    except IOError as e:
        raise IOError('Cannot open secant.conf file: ' + os.path.split(os.getcwd())[-1])
    return [x[1] for x in cp.items('asection') if x[0] == key][0]

def setLogging():
    if os.path.split(os.getcwd())[-1] == 'lib':
        secant_conf_path = '../conf/secant.conf'
    else:
        if os.path.split(os.getcwd())[-1] == 'secant':
            secant_conf_path = 'conf/secant.conf'
        else:
            secant_conf_path = '../../conf/secant.conf'

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



