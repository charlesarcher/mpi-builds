#!/usr/bin/python
import sys
import re

SYMBOL_TO_MEASURE = ""
#SYMBOL_TO_MEASURE = "libmpi.so:MPI_Isend"
#LIBRARY_TO_SKIP = ""
LIBRARY_TO_SKIP = ""

# DEBUG LEVEL
#   0: Modules only
#   1: Instruction groups and Modules
#   2: Instructions, Instruction groups and Modules
DEBUG_LEVEL = 1

# SHOW SKIPPED
#   0: do not show skipped instructions
#   1: show skipped instructions
SHOW_SKIPPED = 1

infile = sys.argv[1]
prev_symbol = ""
prev_module = ""
symbol_count = 0
module_count = 0

skip = 1

symbol_list = []

module_before = ""

already_found = 0

section_count = 0

total_count = 0
total_measured_count = 0
total_skipped_count = 0


for line in open(infile, 'r'):
    if re.search(' INS ',line.strip()):
        symbol = line.strip().split()[3].split('+')[0]
        module = symbol.split(':')[0]

        # First symbol
        if prev_symbol == "" and prev_module == "":
            prev_symbol = symbol
            prev_module = module

        # New symbol
        if symbol != prev_symbol:
            if (prev_symbol == SYMBOL_TO_MEASURE) and (not already_found):
                print "[START] " + SYMBOL_TO_MEASURE + " (skipped section: " + str(section_count) + ")"
                section_count = 0
                skip = 0

            if (DEBUG_LEVEL >= 1) and ((not skip) or SHOW_SKIPPED):
                print "     V      " + prev_symbol + " " + str(symbol_count)

            # New module
            if module != prev_module:
                if (not skip) or SHOW_SKIPPED:
                    print "###### " + prev_module + " " + str(module_count)
                section_count += module_count

                if (module_before == "") and (module == LIBRARY_TO_SKIP):
                    module_before = prev_module
                    skip = 1
                    total_measured_count += section_count
                    print "[START SKIPPING] " + LIBRARY_TO_SKIP + " (section: " + str(section_count) + " - total: " + str(total_measured_count) + ")"
                    section_count = 0
                elif module_before and (module == module_before):
                    print "[STOP SKIPPING] " + LIBRARY_TO_SKIP + " (section: " + str(section_count) + ")"
                    total_skipped_count += section_count
                    module_before = ""
                    section_count = 0
                    skip = 0

                module_count = 0
                prev_module = module

            if (prev_symbol == SYMBOL_TO_MEASURE) and already_found:
                total_measured_count += section_count
                print "[STOP] " + SYMBOL_TO_MEASURE + " (section: " + str(section_count) + " - total: " + str(total_measured_count) + ")"
                skip = 1

            if (prev_symbol == SYMBOL_TO_MEASURE) and (not already_found):
                already_found = 1

            symbol_count = 0
            prev_symbol = symbol


        if (DEBUG_LEVEL >= 2) and ((not skip) or SHOW_SKIPPED):
            print line.strip()

        symbol_count += 1
        module_count += 1
        total_count  += 1

# Last symbol
if (not skip) or SHOW_SKIPPED:
    if DEBUG_LEVEL >= 1:
         print "     V      " + prev_symbol + " " + str(symbol_count)
    print "###### " + prev_module + " " + str(module_count)

print "\n++++++[ Totals ]++++++"
if SYMBOL_TO_MEASURE:
    print " " + SYMBOL_TO_MEASURE + " = " + str(total_measured_count) + " instruction(s)"
if LIBRARY_TO_SKIP:
    print " " + LIBRARY_TO_SKIP + " = " + str(total_skipped_count) + " instruction(s)"
print " Total count = " + str(total_count) + " instruction(s)"
