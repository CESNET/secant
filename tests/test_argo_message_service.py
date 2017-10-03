#!/usr/bin/env python
import time, logging, sys, urllib2, sys, ConfigParser
from argo_ams_library import ArgoMessagingService, AmsException, AmsMessage, AmsException


import unittest

def pullAllMessages(ams, subscription, log):
    ackids = list()
    log.debug("Empty message queue before the test")
    for id, msg in ams.pull_sub(subscription, 60):
        msgid = msg.get_msgid()
        log.debug("Pull message with ID:{id}".format(id=msgid))
        ackids.append(id)

    if ackids:
        ams.ack_sub(subscription, ackids)



class TestArgoMessageService(unittest.TestCase):
    def testPushAndPull(self):
        settings = ConfigParser.ConfigParser()
        settings.read(os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'argo.conf'
        host = settings.get('AMS-GENERAL', 'host')
        project = settings.get('AMS-GENERAL', 'project')
        token = settings.get('AMS-GENERAL', 'token')
        subscription = settings.get('REQUESTS', 'subscription')
        topic = settings.get('REQUESTS', 'topic')

        log = logging.getLogger("TestArgoMessageService.testPushAndPull")

        log.debug("Host: {host}, Project: {project}, Topic: {topic}".format(host=host,
                                                                         project=project,
                                                                         topic=topic))
        ams = ArgoMessagingService(endpoint=host, token=token, project=project)

        pullAllMessages(ams, subscription, log)

        response = urllib2.urlopen("https://vmcaster.appdb.egi.eu/store/vappliance/demo.va.public/image.list",
                                   timeout=5)
        content = response.read()

        msg = AmsMessage(data=content, attributes={'index': '1'}).dict()
        try:
            ret = ams.publish(topic, msg)
            log.debug("Successfully published with ID:{id}".format(id=ret['messageIds'][0]))
        except AmsException as e:
            print e

        # Wait 10 seconds between pull and push
        log.debug("Waiting 10s between push and pull")
        time.sleep(10)

        ackids = list()
        pull_result = ams.pull_sub(subscription, 1)
        if pull_result:
            log.debug("Successfully pulled a message with ID:{id}".format(id=pull_result[0][1].get_msgid()))

        self.assertEquals(content, pull_result[0][1].get_data())

        ackids.append(pull_result[0][1].get_msgid())
        # Send Acknowledgement
        if ackids:
            ams.ack_sub(subscription, ackids)



if __name__ == '__main__':
    logging.basicConfig(stream=sys.stderr)
    logging.getLogger("TestArgoMessageService.testPushAndPull").setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    unittest.main()
