import os, json, sys
import logging

fin = "/run/cloud-init/result.json"
if os.path.exists(fin):
        ret = json.load(open(fin, "r"))
        if len(ret['v1']['errors']):
            sys.exit('Cloud-init finished with errors:' + "\n".join(ret['v1']['errors']))
        else:
            sys.exit('Cloud-init finished with no errors.')
else:
    sys.exit('1')