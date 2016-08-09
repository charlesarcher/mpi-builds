#!/bin/sh

trap "kill 0" SIGINT
yell()      { echo "$0: $*" >&2; }
yellspace() { echo "     -----> $0: $*" >&2; }
die()       { yell "$*"; exit 111; }
try()       { "$@" || die "cannot $*"; }

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi>"
    exit
fi

COMPILER=$1
mkdir -p logs
rm -f logs/*
for FLAVOR in mvapich_base ch3_base_ts ch3_base_tg ch4_base_tpo ch4_base_ts ch4_base_tg ompi_base impi_base ompi_stock mvapich_stock; do
(
    cmd="sh ./build.sh ${COMPILER} ${FLAVOR}"
    echo ${cmd}
    (eval $cmd > logs/${COMPILER}.${FLAVOR}.log 2>&1 || yellspace "FATAL: Command was '$cmd'") &
    wait
) &
done
wait ; exit
