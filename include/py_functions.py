import ConfigParser
import logging
import errno,sys,os

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
        logging.basicConfig(format='%(asctime)s %(message)s', filename=getSettingsFromBashConfFile('../conf/secant.conf', 'log_file'),level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S')
    else:
        if os.path.split(os.getcwd())[-1] == 'secant':
            logging.basicConfig(format='%(asctime)s %(message)s', filename=getSettingsFromBashConfFile('conf/secant.conf', 'log_file'),level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S')
        else:
            logging.basicConfig(format='%(asctime)s %(message)s', filename=getSettingsFromBashConfFile('../../conf/secant.conf', 'log_file'),level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S')

