#!/bin/sh

trap "kill 0" SIGINT
yell()      { echo "$0: $*" >&2; }
yellspace() { echo "     -----> $0: $*" >&2; }
die()       { yell "$*"; exit 111; }
try()       { "$@" || die "cannot $*"; }

mkdir -p logs
rm -f logs/*
for COMPILER in gnu intel clang; do
    for FLAVOR in debug optimized; do
        (
            cmd="sh ./build.sh ${COMPILER} ${FLAVOR}"
            echo ${cmd}
            (eval $cmd > logs/${COMPILER}.${FLAVOR}.log 2>&1 || yellspace "FATAL: Command was '$cmd'") &
            wait
        ) # &  <  put the & here for parallel
    done
done
wait ; exit

