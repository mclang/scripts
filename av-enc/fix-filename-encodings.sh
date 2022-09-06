#!/bin/bash

# Possible fixed for files coming from Windwos:
# convmv -r -f windows-1252 -t UTF-8 .
# convmv -r -f ISO-8859-1 -t UTF-8 .
# convmv -r -f cp-850 -t UTF-8 .

# Converts filenames messed up by Windows to UTF-8:
# NOTE: Does not convert by default, use `--notest` to make the changes
convmv -r -f ISO-8859-1 -t UTF-8 <directory> 2> /dev/null
