import re
import sys
import fileinput
from lxml import etree

lynis =  etree.Element('LYNIS_TEST')

lynis_data = sys.stdin.readlines()
error_line = re.search('(Error:.+)', lynis_data[0])

if error_line:
    error = etree.SubElement(lynis, "ERROR")
    error.text = re.sub('Error: ', '', error_line.group(1))
else:
    warnings = etree.SubElement(lynis, "WARNINGS")
    suggestions = etree.SubElement(lynis, "SUGGESTIONS")

    for line in lynis_data:
        warning_line = re.search('(Warning:.+) (\[.*-*])', line)
        if warning_line:
               test_id = etree.SubElement(warnings, re.sub(r'\[', '', warning_line.group(2)).replace(']', ''))
               test_id.text = re.sub('Warning: ', '', warning_line.group(1))
        else:
            suggestion_line = re.search('(Suggestion:.+) (\[.*-*])' , line)
            if not suggestion_line:
                suggestion_line = re.search('(Suggestion:.+)' , line)
                if suggestion_line:
                    none = etree.SubElement(suggestions, "NONE")
                    none.text = re.sub('Suggestion: ', '', suggestion_line.group(1))
            else:
                if suggestion_line:
                    test_id = etree.SubElement(suggestions, re.sub(r'\[', '', suggestion_line.group(2)).replace(']', ''))
                    test_id.text = re.sub('Suggestion: ', '', suggestion_line.group(1))

print etree.tostring(lynis,pretty_print=True)


