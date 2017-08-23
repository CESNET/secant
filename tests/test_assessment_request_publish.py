#!/usr/bin/env python

from argparse import ArgumentParser
from argo_ams_library import ArgoMessagingService, AmsMessage, AmsException
import base64

def main():
    parser = ArgumentParser(description="AMS message publish")
    parser.add_argument('--host', type=str, default='', help='FQDN of AMS Service')
    parser.add_argument('--token', type=str, default='', help='Given token')
    parser.add_argument('--project', type=str, default='appdb-sec-test', help='Project  registered in AMS Service')
    parser.add_argument('--topic', type=str, default='VMISECURITY-REQUESTS', help='Given topic')
    parser.add_argument('--id', type=str, default='', help='Appliance id')
    args = parser.parse_args()

    ams = ArgoMessagingService(endpoint=args.host, token=args.token, project=args.project)
    msg = AmsMessage(data=" ", attributes={'NIFTY_APPLIANCE_ID': args.id}).dict()
    try:
        ret = ams.publish(args.topic, msg)
        print ret
    except AmsException as e:
        print e

main()