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
        raise IOError('Cannot open secant.conf file')
    return [x[1] for x in cp.items('asection') if x[0] == key][0]

def setLogging():
    logging.basicConfig(format='%(asctime)s %(message)s', filename=getSettingsFromBashConfFile('../../conf/secant.conf', 'log_file'),level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S')