#!/usr/bin/env python

import os
import sys
import argparse

secant_path = os.path.dirname(os.path.realpath(__file__)) + "/.."
sys.path.append(secant_path + "/include")
from argo_communicator import ArgoCommunicator

parser = argparse.ArgumentParser(description='ARGO communicator')
parser.add_argument('--mode', help='Mode: pull/push', required=True)
parser.add_argument('--niftyID', help='Nifty identifier of analyzed template', required=True)
parser.add_argument('--messageID', help='Message identifier of analyzed template', required=True)
parser.add_argument('--path', help='Path to XML data', required=True)
parser.add_argument('--base_mpuri', help='The BASE_MPURI identifier for the VA', required=True)
args = vars(parser.parse_args())

if args['mode'] == 'push':
    argo = ArgoCommunicator()
    argo.post_assessment_results(args['niftyID'], args['messageID'], args['path'], args['base_mpuri'])
