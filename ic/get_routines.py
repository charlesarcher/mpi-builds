#!/usr/bin/python
import sys
import re
from collections import defaultdict

module_list = []
symbol_list = []

module_count = defaultdict(lambda: 0)
symbol_count = defaultdict(lambda: 0)


infile = sys.argv[1]

for line in open(infile, 'r'):
    if re.search(' INS ',line.strip()):
        x = line.strip().split()[3].split('+')[0]
        y = x.split(':')[0]
        symbol_count[x] += 1
        module_count[y] += 1

for x in sorted(module_count, key=module_count.get, reverse=True):
    print x + ' ' + str(module_count[x])
    d2 = dict((k, v) for k, v in symbol_count.items() if re.search(x, k))
    for y in sorted(d2, key=d2.get, reverse=True):
        print '\t' + y + ' ' + str(symbol_count[y])


    
