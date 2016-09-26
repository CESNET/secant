import re, sys, os, fileinput, logging
from lxml import etree

sys.path.append('../../include/')
import py_functions

template_id = sys.argv[1]
py_functions.setLogging()
lynis = etree.Element('LYNIS_TEST')

lynis_data = sys.stdin.readlines()
#error_line = re.search('(Error:.+)', lynis_data[0])

#if error_line:
#    error = etree.SubElement(lynis, "ERROR")
#    error.text = re.sub('Error: ', '', error_line.group(1)))
error_message = re.search('Error: Missing Lynis report.*', lynis_data[0])
if lynis_data[0] == 'FAIL':
    lynis.set('status', 'FAIL')
elif lynis_data[0] == 'SKIP':
    lynis.set('status', 'SKIP')
elif error_message:
    lynis.set('status', 'FAIL')
else:
    logging.debug('[%s] %s: Start LYNIS_TEST reporter.', template_id, 'DEBUG')
    logging.debug('[%s] %s: Start LYNIS_TEST reporter.', template_id, 'DEBUG')
    warnings = etree.SubElement(lynis, "WARNINGS")
    suggestions = etree.SubElement(lynis, "SUGGESTIONS")
    for line in lynis_data:
        try:
            warning_line = re.search('(Warning:.+.\[test:.[A-Z,\-,0-9]+.])', line)
            if not warning_line:
                warning_line = re.search('(Warning:.+)', line)
                if warning_line:
                    none = etree.SubElement(warnings, "NONE")
                    none.text = re.sub('Warning: ', '', warning_line.group(1))
                    continue
            elif warning_line:
                    split_to_text_and_id = warning_line.group(0).split("[test:")
                    warning_text = re.sub('Warning: ', '', split_to_text_and_id[0])
                    test_id = re.sub(']', '', split_to_text_and_id[1])
                    test_id = etree.SubElement(warnings, test_id)
                    test_id.text = warning_text
                    continue
        except ValueError as e:
            logging.debug('[%s] %s: LYNIS_TEST reporter failed during warnings parsing: %s.', template_id, 'ERROR', str(e))
            lynis.set('status', 'FAIL')
            break;

        try:
            suggestion_line = re.search('(Suggestion:.+.\[test:.[A-Z,\-,0-9]+.])', line)
            if not suggestion_line:
                suggestion_line = re.search('(Suggestion:.+)', line)
                if suggestion_line:
                    none = etree.SubElement(suggestions, "NONE")
                    none.text = re.sub('Suggestion: ', '', suggestion_line.group(1))
                    continue
            elif suggestion_line:
                    split_to_text_and_id = suggestion_line.group(0).split("[test:")
                    suggestion_text = re.sub('Suggestion: ', '', split_to_text_and_id[0])
                    test_id = re.sub(']', '', split_to_text_and_id[1])
                    test_id = etree.SubElement(suggestions, test_id)
                    test_id.text = suggestion_text
                    continue
        except ValueError as e:
            logging.debug('[%s] %s: LYNIS_TEST reporter failed during suggestions parsing: %s.', template_id, 'ERROR',
                          str(e))
            lynis.set('status', 'FAIL')
            break;

if 'status' not in lynis.attrib:
    lynis.set('status', 'OK')

print etree.tostring(lynis, pretty_print=True)
