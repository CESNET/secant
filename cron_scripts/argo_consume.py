#!/usr/bin/env python
import sys
import subprocess
sys.path.append('../lib/')
from argo_communicator import ArgoCommunicator
import logging, os

if os.path.split(os.getcwd())[-1] == 'lib' or os.path.split(os.getcwd())[-1] == 'cron_scripts':
    sys.path.append('../include')
else:
    sys.path.append('include')

import py_functions

py_functions.setLogging()

def runcmd(cmd):
    try:
        output = subprocess.check_output(cmd)
        print output
        return output
    except:
        print "Failed"
        return None

if __name__ == "__main__":
    argo = ArgoCommunicator()
    secant_conf_path = os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'secant.conf'
    url = py_functions.getSettingsFromBashConfFile(secant_conf_path, "IMAGE_LIST_URL")
    dir = py_functions.getSettingsFromBashConfFile(secant_conf_path, "IMAGE_LIST_DIR")

    for img_list in argo.get_templates_for_assessment(dir):
        #sudo -u cloudkeeper /opt/cloudkeeper/bin/cloudkeeper --image-lists=https://vmcaster.appdb.egi.eu/store/vappliance/demo.va.public/image.list --debug
        logging.debug('[%s] %s: Process image list: ' + img_list, 'SECANT', 'DEBUG')
        #img_list = "https://vmcaster.appdb.egi.eu/store/vappliance/demo.va.public/image.list"
        img_url = "%s/%s" % (url, img_list)
        debug_info = runcmd(["sudo", "-u", "cloudkeeper", "/opt/cloudkeeper/bin/cloudkeeper", "--image-lists=" + img_url, "--debug"])
        logging.debug(debug_info)
