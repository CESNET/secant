from argo_ams_library import ArgoMessagingService, AmsException, AmsMessage, AmsException
import ConfigParser, tempfile, sys, os, logging, argparse
from pathlib2 import Path


if os.getcwd().split('/')[-1] == 'secant':
    sys.path.append('include')
    import py_functions
elif os.getcwd().split('/')[-1] == 'lib' or os.getcwd().split('/')[-1] == 'cron_scripts' or os.getcwd().split('/')[-1] == 'tests':
    sys.path.append('../include')
    import py_functions
    py_functions.setLogging()

py_functions.setLogging()
sys.path.append('../lib')


class ArgoCommunicator(object):

    def __init__(self):
        """Return a Customer object whose name is *name* and starting
        balance is *balance*."""
        settings = ConfigParser.ConfigParser()
        settings.read(os.environ.get('SECANT_CONFIG_DIR', '/etc/secant') + '/' + 'argo.conf')

        self.host = settings.get('AMS-GENERAL', 'host')
        self.project = settings.get('AMS-GENERAL', 'project')
        self.token = settings.get('AMS-GENERAL', 'token')
        self.requestTopic = settings.get('REQUESTS', 'topic')
        self.requestSubscription = settings.get('REQUESTS', 'subscription')
        self.resultTopic = settings.get('RESULTS', 'topic')
        self.resultSubscription = settings.get('RESULTS', 'subscription')
        self.nummsgs = 3

    def post_assessment_results(self, niftyId, file_path):
        ams = ArgoMessagingService(endpoint=self.host, token=self.token, project=self.project)
        contents = Path(file_path).read_text()
        msg = AmsMessage(data=contents, attributes={'NIFTY_APPLIANCE_ID': niftyId}).dict()
        try:
            ret = ams.publish(self.resultTopic, msg)
            logging.debug('[%s] %s: Results has been successfully pushed.', niftyId, 'DEBUG')
        except AmsException as e:
            print e

    def get_assessment_results(self):
        """
         :return:
        """
        ams = ArgoMessagingService(endpoint=self.host, token=self.token, project=self.project)
        ackids = list()
        niftyids = list()
        logging.debug('[%s] %s: Start pulling from the %s subscription', 'SECANT', 'DEBUG', self.resultSubscription)
        pull_subscription = ams.pull_sub(self.resultSubscription, 10, True)
        logging.debug('[%s] %s: Finish pulling from the %s subscription', 'SECANT', 'DEBUG', self.resultSubscription)
        if pull_subscription:
            for id, msg in pull_subscription:
                attr = msg.get_attr()
                data = msg.get_data()
                ackids.append(id)
        else:
            logging.debug('[%s] %s: No new requests to pull in %s subscription', 'SECANT', 'DEBUG', self.resultSubscription)

        if ackids:
            ams.ack_sub(self.resultSubscription, ackids)

        return niftyids

    def get_templates_for_assessment(self):
        """
        :return:
        """
        ams = ArgoMessagingService(endpoint=self.host, token=self.token, project=self.project)
        ackids = list()
        niftyids = list()
        logging.debug('[%s] %s: Start pulling from the %s subscription', 'SECANT', 'DEBUG', self.requestSubscription)
        pull_subscription = ams.pull_sub(self.requestSubscription, self.nummsgs, True)
        logging.debug('[%s] %s: Finish pulling from the %s subscription', 'SECANT', 'DEBUG', self.requestSubscription)
        if pull_subscription:
            for id, msg in pull_subscription:
                attr = msg.get_attr()
                data = msg.get_data()
                image_list_file = tempfile.NamedTemporaryFile(prefix='tmp_', delete=False, suffix='.list')
                image_list_file.write(data)
                image_list_file.close()
                niftyids.append(image_list_file.name)
                ackids.append(id)
        else:
            logging.debug('[%s] %s: No new requests to pull', 'SECANT', 'DEBUG')

        if ackids:
            ams.ack_sub(self.requestSubscription, ackids)

        return niftyids


    def post_template_for_assessment(self, niftyId):
        ams = ArgoMessagingService(endpoint=self.host, token=self.token, project=self.project)
        msg = AmsMessage(data="", attributes={'NIFTY_APPLIANCE_ID': niftyId}).dict()
        try:
            ret = ams.publish(self.requestTopic, msg)
        except AmsException as e:
            print e

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='ARGO communicator')
    parser.add_argument('--mode', help='Mode: pull/push', required=True)
    parser.add_argument('--niftyID', help='Nifty identifier of analyzed template', required=True)
    parser.add_argument('--path', help='Path to XML data', required=True)
    args = vars(parser.parse_args())

    if args['mode'] == 'push':
        argo = ArgoCommunicator()
        argo.post_assessment_results(args['niftyID'], args['path'])


