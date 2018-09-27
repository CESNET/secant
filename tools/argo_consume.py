#!/usr/bin/env python
from __future__ import print_function
import sys
import subprocess
import logging, os
import tempfile
import yaml
import shutil

secant_path = os.path.dirname(os.path.realpath(__file__)) + "/.."
sys.path.append(secant_path + "/include")

import py_functions
from argo_communicator import ArgoCommunicator

py_functions.setLogging()

def fail_report(msgId):
    data = b"""<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<SECANT>
  <VERSION>1.0</VERSION>
  <IMAGE_ID/>
  <DATE>%f</DATE>
  <OUTCOME>INTERNAL_FAILURE</OUTCOME>
  <OUTCOME_DESCRIPTION>Cloudkeeper failed to register image.</OUTCOME_DESCRIPTION>
  <MESSAGEID>%s</MESSAGEID>
</SECANT>""" % (time.time(), msgId)
    report_file = tempfile.NamedTemporaryFile(delete=False)
    report_file.write(data)
    report_file.close()
    return report_file.name

def createTemplate(msgId, secant_conf_path):
    data = ""
    for fileName in [os.path.expanduser('~') + '/.cloudkeeper-one/cloudkeeper-one.yml', '/etc/cloudkeeper-one/cloudkeeper-one.yml']:
        try:
            with open(fileName) as yamlFile:
                data = yaml.load(yamlFile)
        except Exception:
            continue
    if not data:
        logging.error("Couldn't find valid configuration file for cloudkeeper.")
        raise FileNotFoundError("Couldn't find valid configuration file for cloudkeeper.")
    templates = data['cloudkeeper-one']['appliances']['template-dir']
    templates_dest = py_functions.getSettingsFromBashConfFile(secant_conf_path, "CLOUDKEEPER_TEMPLATES_DIR")
    shutil.copyfile(templates+'template.erb', templates_dest+'template.erb')
    shutil.copyfile(templates+'image.erb', templates_dest+'image.erb')
    os.chmod(templates_dest+'template.erb', 0o644)
    with open(templates_dest+'template.erb', 'a') as t:
        t.write('MESSAGEID = "%s"\n' % msgId)
    return (templates_dest+'template.erb'),(templates_dest+'image.erb')

def registerTemplate():
    argo = ArgoCommunicator()
    secant_conf_path = os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'secant.conf'
    url = py_functions.getSettingsFromBashConfFile(secant_conf_path, "IMAGE_LIST_URL")
    dir = py_functions.getSettingsFromBashConfFile(secant_conf_path, "IMAGE_LIST_DIR")
    state_dir = py_functions.getSettingsFromBashConfFile(secant_conf_path, "STATE_DIR")
    log_dir = py_functions.getSettingsFromBashConfFile(secant_conf_path, "LOG_DIR")
    cloudkeeper_endpoint = py_functions.getSettingsFromBashConfFile(secant_conf_path, "CLOUDKEEPER_ENDPOINT")

    registered_dir = state_dir + "/registered"
    if not os.path.isdir(registered_dir):
        os.mkdir(registered_dir, 755)

    images,msgids = argo.get_templates_for_assessment(dir)
    logging.info("Secant consumer: Obtained %d image list(s) for assessment" % (len(images)))

    cloudkeeper_log = open(log_dir + "/cloudkeeper.log", mode="a");

    for (img_list,msgId) in zip(images,msgids):
        #sudo -u cloudkeeper /opt/cloudkeeper/bin/cloudkeeper --image-lists=https://vmcaster.appdb.egi.eu/store/vappliance/demo.va.public/image.list --debug
        #img_list = "https://vmcaster.appdb.egi.eu/store/vappliance/demo.va.public/image.list"
        logging.debug("Secant consumer: Trying to register image list %s for message %s" % (img_list, msgId))
        try:
            template, image = createTemplate(msgId, secant_conf_path)
        except Exception:
            logging.error("Secant consumer: Failed to create template with MESSAGE ID %s from image list %s" % (msgId, img_list))
            continue
        img_url = "%s/%s" % (url, img_list)
        cmd = (["/opt/cloudkeeper/bin/cloudkeeper", "--image-lists=" + img_url, "--debug", "--backend-endpoint=" + cloudkeeper_endpoint])
        try:
            subprocess.check_call(cmd, stdout=cloudkeeper_log, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            report=fail_report(msgId)
            try:
                argo.post_assessment_results("", msgId, report, "")
            except Exception:
                logging.error("Failed to send fail report.")
            finally:
                os.remove(report)
            logging.error("Secant consumer: Registering image list %s failed: %s" % (img_list, e.output))
            print("Failed to register image %s, check the log." % img_list, file=sys.stderr)
            continue
        finally:
            os.remove(template)
            os.remove(image)
        reg_list = tempfile.NamedTemporaryFile(prefix='image_list_', delete=False, dir=registered_dir)
        os.rename("%s/%s" % (dir, img_list), reg_list.name)
        logging.debug("Secant consumer: Image list %s has been registered as %s with message ID %s" % (img_list, os.path.basename(reg_list.name), msgId))
        if subprocess.call([secant_path + "/tools/cloudkeeper_check.sh", msgId]) == 1:
            logging.error("Secant consumer: Image list %s with message id %s is not in OpenNebula templates" % (img_list,msgId))

    cloudkeeper_log.close()

secant_conf_path = os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'secant.conf'
lock_file = py_functions.getSettingsFromBashConfFile(secant_conf_path, "ARGO_LOCK_FILE")
if (os.path.isfile(lock_file)):
    raise RuntimeError("Script is already running.")

try:
    f = os.open(lock_file, os.O_CREAT|os.O_EXCL|os.O_RDWR)
    registerTemplate()
finally:
    os.close(f)
    os.unlink(lock_file)
