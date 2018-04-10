#!/usr/bin/python

import sys
import os

name = sys.argv[1]

status = sys.stdin.readline().rstrip(os.linesep)
print("<%s status=\"%s\">" % (name, status))

summary = sys.stdin.readline().rstrip(os.linesep)
if summary:
    print("\t<summary>%s</summary>" % summary)

    print("\t<details>")
    for line in sys.stdin:
        # XXX Add escaping !
        print(line.rstrip(os.linesep))
    print("\t</details>")

print("</%s>" % name)
