#!/usr/bin/env python3
import sys

import docutils.frontend
import docutils.parsers
import docutils.parsers.rst

fp = sys.argv[1]
f = open(fp)

default_settings = docutils.frontend.OptionParser(
    components=(docutils.parsers.rst.Parser,)).get_default_values()
document = docutils.utils.new_document(f.name, default_settings)
parser = docutils.parsers.rst.Parser()
parser.parse(f.read(), document)
print(document[0]['names'][0])
