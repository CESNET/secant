#!/usr/bin/python

import sys
import os

name = sys.argv[1]

status = sys.stdin.readline()
status = status.rstrip(os.linesep)

print("<%s status=\"%s\">" % (name, status))

print("\t<outcome>")
for line in sys.stdin:
    # Escaping, ... !
    print(line.rstrip(os.linesep))
print("\t</outcome>")

print("</%s>" % name)
