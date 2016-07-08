import re, sys, os, fileinput, logging
from lxml import etree

# print os.path.split(os.getcwd())
# if os.path.split(os.getcwd())[-1] == 'lib':
#     sys.path.append('../include/')
#     print "A"
# else:
#     if os.path.split(os.getcwd())[-1] == 'secant':
#         sys.path.append('include/')
#         print "B"

sys.path.append('../../include/')
import py_functions

template_id = sys.argv[1]
py_functions.setLogging()
logging.debug('[%s] %s: Start LYNIS_TEST reporter.', template_id, 'DEBUG')
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
            suggestion_line = re.search('(Suggestion:.+.\[test:.[A-Z,\-,0-9]+.])', line)
            if not suggestion_line:
                suggestion_line = re.search('(Suggestion:.+)' , line)
                if suggestion_line:
                    none = etree.SubElement(suggestions, "NONE")
                    none.text = re.sub('Suggestion: ', '', suggestion_line.group(1))
            else:
                if suggestion_line:
                    split_to_text_and_id = suggestion_line.group(0).split("[test:")
                    suggestion_text = re.sub('Suggestion: ', '', split_to_text_and_id[0])
                    test_id = re.sub(']', '', split_to_text_and_id[1])
                    test_id = etree.SubElement(suggestions, test_id)
                    test_id.text = suggestion_text

print etree.tostring(lynis,pretty_print=True)


