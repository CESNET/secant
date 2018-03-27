#!/usr/bin/python

import sys
import os

name = sys.argv[1]

status = sys.stdin.readline()
status = status.rstrip(os.linesep)

print("<%s>" % name)
print("\t<status=\"%s\" />" % status)

if status != "SKIP":
  print("\t<outcome>")
  for line in sys.stdin:
      # Escaping, ... !
      print(line.rstrip(os.linesep))
  print("\t</outcome>")

print("</%s>" % name)
