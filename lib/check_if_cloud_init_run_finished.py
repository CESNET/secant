import os, json, sys
import logging

external_tests_path=""
internal_tests_path=""
if os.path.split(os.getcwd())[-1] == 'lib':
    sys.path.append('../include')
else:
    sys.path.append('include')

import py_functions
py_functions.setLogging()

fin = "/run/cloud-init/result.json"
if os.path.exists(fin):
        ret = json.load(open(fin, "r"))
        if len(ret['v1']['errors']):
                logging.debug('[%s] %s: Cloud-init finished with errors:' + "\n".join(ret['v1']['errors']), template_id, 'DEBUG')
        else:
                logging.debug('[%s] %s: Cloud-init finished finished with no errors.", template_id, 'DEBUG')
        sys.exit(0)
else:
        sys.exit(1)