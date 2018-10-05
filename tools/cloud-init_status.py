#!/usr/bin/env python3

import json
import sys

"""
Code is based on https://github.com/cloud-init/cloud-init/blob/master/cloudinit/cmd/status.py
Controlling actual status of cloud init
exit 0 - status: done
exit 1 - status: running
exit 2 - status: error
"""

with open(sys.argv[1]) as f:
    data = json.load(f)

errors = []
latest_event = 0
for key, value in sorted(data['v1'].items()):
    if key == 'stage':
        if value:
            sys.exit(1)
    elif isinstance(value, dict):
        errors.extend(value.get('errors', []))
        start = value.get('start') or 0
        finished = value.get('finished') or 0
        if finished == 0 and start != 0:
            sys.exit(1)
        event_time = max(start, finished)
        if event_time > latest_event:
            latest_event = event_time
if errors:
    sys.exit(2)
elif latest_event > 0:
    sys.exit(0)
