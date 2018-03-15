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
    except:
        raise

    return output

if __name__ == "__main__":
    argo = ArgoCommunicator()
    secant_conf_path = os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'secant.conf'
    url = py_functions.getSettingsFromBashConfFile(secant_conf_path, "IMAGE_LIST_URL")
    dir = py_functions.getSettingsFromBashConfFile(secant_conf_path, "IMAGE_LIST_DIR")
    state_dir = py_functions.getSettingsFromBashConfFile(secant_conf_path, "STATE_DIR")
    registered_dir = state_dir + "/registered"
    if not os.path.isdir(registered_dir):
        os.mkdir(registered_dir, 755)

    images = argo.get_templates_for_assessment(dir)
    logging.info("Secant consumer: Obtained %d image list(s) for assessment" % (len(images)))

    for img_list in images:
        #sudo -u cloudkeeper /opt/cloudkeeper/bin/cloudkeeper --image-lists=https://vmcaster.appdb.egi.eu/store/vappliance/demo.va.public/image.list --debug
        #img_list = "https://vmcaster.appdb.egi.eu/store/vappliance/demo.va.public/image.list"
        logging.debug("Trying to register image list %s" % (img_list))
        img_url = "%s/%s" % (url, img_list)
        try:
            debug_info = runcmd(["sudo", "-u", "cloudkeeper", "/opt/cloudkeeper/bin/cloudkeeper", "--image-lists=" + img_url, "--debug"])
        except:
            logging.error("Secant consumer: Registering image list %s failed: %s" % (img_list, debug_info))
            continue
        logging.debug("Secant consumer: Image list %s has been registered" % (img_list))
        os.rename("%s/%s" % (dir, img_list), "%s/%s" % (registered_dir, img_list))
