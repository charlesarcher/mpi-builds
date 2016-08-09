#!/usr/bin/python
import sys
import re

infile = sys.argv[1]
last_symbol = ""
last_module = ""
symbol_count = 0
module_count = 0

instructions_not_skipped = 0

symbol_list = []

module_before = ""

lib_to_skip = "libportals.so.4"

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
                if module_before == "":
                    print last_module, module_count
#                    for s in symbol_list:
#                        print "\t" + s
                    instructions_not_skipped += module_count
                if module == lib_to_skip:
                    if module_before == "":
                        print "========= Entering " + lib_to_skip + " (" + symbol + ") after " + str(instructions_not_skipped) + " ========="
                        module_before = last_module
                        instructions_not_skipped = 0
                elif module == module_before:
                    print "========= Leaving " + lib_to_skip + " (" + symbol + ") ========="
                    module_before = ""
                symbol_list = []
                module_count = 0
                last_module = module


        symbol_count += 1
        module_count += 1

symbol_list.append(last_symbol + " " + str(symbol_count))
print module, module_count
#for s in symbol_list:
#    print "\t" + s
