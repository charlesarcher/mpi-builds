#!/bin/sh

trap "kill 0" SIGINT

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 exe name"
    exit
fi

EXE=$1

#ldd exe/${EXE}
#exit 0
if [ -z "${PMI_RANK}" ]; then
    PMI_RANK=${OMPI_COMM_WORLD_RANK}
fi

rank=${PMI_RANK}
if [ ${rank} -eq 0 ] ; then
echo "Tracing on rank ${rank}"
#    -mix                      \
#    -debugtrace               \
#    -footprint                \
#    -fp-icount 10000          \
#    -pinlit2                  \
#    -mix                      \

/opt/intel/sde/sde64          \
    -pinlit2                  \
    -debugtrace               \
    -start_ssc_mark 400:1     \
    -stop_ssc_mark  410:1     \
    -log:mt                   \
    -log:focus_thread 1       \
    -dt_out sdelog/${EXE}.sdelog  \
    -dt_symbols 1             \
    -dt_flush                 \
    -mix                                 \
    -omix   sdelog/${EXE}.mixlog         \
    -footprint                           \
    -ofootprint sdelog/${EXE}.footprint  \
    -length 2000000000        \
    -- ./exe/${EXE}
else
echo "Not Tracing on rank ${rank}"
./exe/${EXE}
fi
