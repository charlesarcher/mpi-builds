#!/usr/bin/python
import sys
import re

infile = sys.argv[1]
last_symbol = ""
last_module = ""
symbol_count = 0
module_count = 0

symbol_list = []

for line in open(infile, 'r'):
    if re.search(' INS ',line.strip()):
        symbol = line.strip().split()[3].split('+')[0]
        module = symbol.split(':')[0]

        if last_symbol == "":
            last_symbol = symbol

        if last_module == "":
            last_module = module

        if last_symbol != symbol:
            symbol_list.append(last_symbol + " " + str(symbol_count))
            symbol_count = 0
            last_symbol = symbol
            if last_module != module:
                print last_module, module_count
                for s in symbol_list:
                    print "\t" + s
                symbol_list = []
                module_count = 0
                last_module = module


        symbol_count += 1
        module_count += 1

symbol_list.append(last_symbol + " " + str(symbol_count))
print module, module_count
for s in symbol_list:
    print "\t" + s
