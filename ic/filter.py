#!/usr/bin/python
import os,re,types,math
import sys
import re
from collections import defaultdict

subdir='sdelog.bak'
os.chdir(subdir)
os.listdir(os.curdir)

extensions = ['sdelog' ] ;
file_names = [fn for fn in os.listdir(os.curdir) if any([fn.endswith(ext) for ext in extensions])];

for name in file_names:
    outfile = open(name+".filtered", 'w')
    for line in open(name, 'r'):
        if re.search(' INS ',line.strip()):
            x = line.strip()
            print >> outfile, x
            # if not "psmi_" in x and \
            #    not "psm_" in x and \
            #    not "psmx_" in x and \
            #    not "hfi_" in x and \
            #    not "_int_malloc" in x and \
            #    not "_malloc" in x and \
            #    not "memcpy" in x and \
            #    not "pthread_" in x and \
            #    not "ips_" in x:
            #     print >> outfile, x
    outfile.close()
