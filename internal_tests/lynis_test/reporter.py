import re
import sys
from lxml import etree

lynis =  etree.Element('LYNIS')
warnings = etree.SubElement(lynis, "WARNINGS")

if len(sys.argv) != 2:
    sys.stderr.write("Wrong number of arguments\n")
    sys.exit(1)

with open(sys.argv[1]) as f:
    for line in f:
        warning_line = re.search('(Warning:.+) (\[test:.*])', line)
        if warning_line:
           test_id = etree.SubElement(warnings, re.sub(r'\[test:', '', warning_line.group(2)).replace(']', ''))
           test_id.text = re.sub('Warning: ', '', warning_line.group(1))

suggestions = etree.SubElement(lynis, "SUGGESTIONS")
with open(sys.argv[1]) as f:
    for line in f:
        suggestion_line = re.search('(Suggestion:.+) (\[test:.*])' , line)

        if not suggestion_line:
            suggestion_line = re.search('(Suggestion:.+)' , line)
            if suggestion_line:
                none = etree.SubElement(suggestions, "NONE")
                none.text = re.sub('Suggestion: ', '', suggestion_line.group(1))
        else:
            if suggestion_line:
                test_id = etree.SubElement(suggestions, re.sub(r'\[test:', '', suggestion_line.group(2)).replace(']', ''))
                test_id.text = re.sub('Suggestion: ', '', suggestion_line.group(1))

print etree.tostring(lynis,pretty_print=True)


