#!/bin/bash


for x in sdelog.bak/*.sdelog; do
    y=$(basename $x)
    python measure_instruction_count.py $x > ic/"${y%.*}".ic

done
