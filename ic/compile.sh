#!/bin/sh
trap "kill 0" SIGINT

yell() { echo "$0: $*" >&2; }
die()  { yell "$*"; exit 111; }
try()  { "$@" || die "cannot $*"; }


if [ $# -lt 4 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi> <MPI> <static|dynamic> <outname>"
    exit 1
fi

#example
#MPI=optimized-ofi-ts-inline-ep-dynamic-map-disabled


PWD=$(pwd)
HOME=/home/cjarcher/
COMPILER=$1
MPI=$2
STATIC=$3
OUTNAME=$4
MPICH2DIR=${PWD}/ssg_sfi-mpich
THREAD_LEVEL=default

export AUTOCONFTOOLS=${HOME}/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:/bin:/usr/bin:.
case $COMPILER in
    intel )
        . ${HOME}/intel_compilervars.sh intel64
        . ${HOME}/code/setup_intel.sh
        export INTELMPICC=mpiicc
        ;;
    gnu )
        if [ -e /opt/rh/devtoolset-3/enable ]; then
            . /opt/rh/devtoolset-3/enable
        fi
        . ${HOME}/code/setup_gnu.sh
        export INTELMPICC=mpicc
        ;;
    clang )
        if [ -e /opt/rh/devtoolset-3/enable ]; then
            . /opt/rh/devtoolset-3/enable
        fi
        . ${HOME}/code/setup_clang.sh
        export INTELMPICC=mpicc
        ;;
    * )
        echo "Unknown compiler type"
        exit
esac

OPTFLAGS_COMMON="-Wall -g3 -O3 ${MCMODEL} -DNDEBUG ${EXTRA_OPT}"
OPTLDFLAGS_COMMON="-O3 ${MCMODEL} ${EXTRA_LD_OPT}"
DEBUGFLAGS_COMMON="-Wall -g3 ${MCMODEL} -O0 ${EXTRA_DEBUG}"
DEBUGLDFLAGS_COMMON="-O0 ${MCMODEL} ${EXTRA_LD_DEBUG}"

export CFLAGS=${OPTFLAGS_COMMON}
export CXXFLAGS=${OPTFLAGS_COMMON}
export LDFLAGS=${OPTLDFLAGS_COMMON}

case $STATIC in
    static )
        if [ ${OUTNAME} != "mvapich_ib" ]; then
            STATICFLAG=-static
        fi
        EXTRAS=""
        if [ "$MPI" = "netmod-opt" ]; then
            EXTRAS="${EXTRAS}  -L/home/cjarcher/code/install/intel/mxm/lib -lmxm -lz -lrt -libverbs -lbfd -liberty -lz"
        fi
        ;;
    dynamic )
        ;;
    * )
        echo "Unknown compile type <static|dynamic>"
        exit
esac

case $MPI in
    /opt/intel/impi/2017/intel64 )
        MPIBASE=/opt/intel/impi/2017/intel64
        MPICC=${MPIBASE}/bin/${INTELMPICC}
        ;;
    /usr/mpi/gcc/openmpi-1.10.2-hfi )
        MPIBASE=/usr/mpi/gcc/openmpi-1.10.2-hfi
        MPICC=${MPIBASE}/bin/mpicc
        ;;
    /usr/mpi/intel/openmpi-1.10.2-hfi )
        MPIBASE=/usr/mpi/intel/openmpi-1.10.2-hfi
        MPICC=${MPIBASE}/bin/mpicc
        ;;
    /usr/mpi/gcc/mvapich2-2.1-hfi )
        MPIBASE=/usr/mpi/gcc/mvapich2-2.1-hfi
        MPICC=${MPIBASE}/bin/mpicc
        ;;
    /usr/mpi/intel/mvapich2-2.1-hfi )
        MPIBASE=/usr/mpi/intel/mvapich2-2.1-hfi
        MPICC=${MPIBASE}/bin/mpicc
        export CFLAGS=$(echo $CFLAGS | sed -e 's/-ipo//')
        export LDFLAGS=$(echo $LDFLAGS | sed -e 's/-ipo//')
        ;;
    * )
        MPIBASE=/home/cjarcher/code/install/${COMPILER}/${MPI}
        MPICC=${MPIBASE}/bin/mpicc
        ;;
esac

OTHERBASE=/home/cjarcher/code/install/${COMPILER}/ofi
case $COMPILER in
    intel )
        export EXTRA_LD_OPT="${EXTRA_LD_OPT} -qopt-report-file=ipo-report.out"
        export EXTRA_LD_OPT="${EXTRA_LD_OPT} -qopt-report-phase=all"
        export EXTRA_LD_OPT="${EXTRA_LD_OPT} -qopt-report=5"
        export OPTREPORTISEND="-qopt-report-file=optreport/isend.${COMPILER}.${STATIC}.${OUTNAME} -qopt-report-phase=ipo -qopt-report=5"
        export OPTREPORTSEND="-qopt-report-file=optreport/send.${COMPILER}.${STATIC}.${OUTNAME} -qopt-report-phase=ipo -qopt-report=5"
        export OPTREPORTIRECV="-qopt-report-file=optreport/irecv.${COMPILER}.${STATIC}.${OUTNAME} -qopt-report-phase=ipo -qopt-report=5"
        export OPTREPORTRECV="-qopt-report-file=optreport/recv.${COMPILER}.${STATIC}.${OUTNAME} -qopt-report-phase=ipo -qopt-report=5"
        export OPTREPORTPUT="-qopt-report-file=optreport/put.${COMPILER}.${STATIC}.${OUTNAME} -qopt-report-phase=ipo -qopt-report=5"
        export OPTREPORTPUTSYNC="-qopt-report-file=optreport/putsync.${COMPILER}.${STATIC}.${OUTNAME} -qopt-report-phase=ipo -qopt-report=5"
        export OPTREPORTSENDWAIT="-qopt-report-file=optreport/sendwait.${COMPILER}.${STATIC}.${OUTNAME} -qopt-report-phase=ipo -qopt-report=5"
        export OPTREPORTRECVWAIT="-qopt-report-file=optreport/recvwait.${COMPILER}.${STATIC}.${OUTNAME} -qopt-report-phase=ipo -qopt-report=5"
        SOURCE="flood.c"
        ;;
    *)
        SOURCE='flood.c'
        ;;
esac


CFLAGS="$CLFAGS -Wl,--warn-unresolved-symbols"

cmd="${MPICC} ${CFLAGS} ${STATICFLAG} ${LDFLAGS} ${SOURCE} ${OPTREPORTISEND} -DUSE_ISEND -o exe/isend.${COMPILER}.${STATIC}.${OUTNAME} ${EXTRAS}"
echo $cmd | sed 's/ \{1,\}/ /g'
(eval $cmd) &
pid0=$!

cmd="${MPICC} ${CFLAGS} ${STATICFLAG} ${LDFLAGS} ${SOURCE} ${OPTREPORTSEND} -o exe/send.${COMPILER}.${STATIC}.${OUTNAME} ${EXTRAS}"
echo $cmd | sed 's/ \{1,\}/ /g'
(eval $cmd) &
pid1=$!

cmd="${MPICC} ${CFLAGS} ${STATICFLAG} ${LDFLAGS} ${SOURCE} ${OPTREPORTIRECV} -DUSE_IRECV -o exe/irecv.${COMPILER}.${STATIC}.${OUTNAME} ${EXTRAS}"
echo $cmd | sed 's/ \{1,\}/ /g'
(eval $cmd) &
pid2=$!

cmd="${MPICC} ${CFLAGS} ${STATICFLAG} ${LDFLAGS} ${SOURCE} ${OPTREPORTRECV} -o exe/recv.${COMPILER}.${STATIC}.${OUTNAME} ${EXTRAS}"
echo $cmd | sed 's/ \{1,\}/ /g'
(eval $cmd) &
pid3=$!

cmd="${MPICC} ${CFLAGS} ${STATICFLAG} ${LDFLAGS} ${SOURCE} ${OPTREPORTSENDWAIT} -DUSE_ISEND -o exe/sendwait.${COMPILER}.${STATIC}.${OUTNAME} ${EXTRAS}"
echo $cmd | sed 's/ \{1,\}/ /g'
(eval $cmd) &
pid4=$!

cmd="${MPICC} ${CFLAGS} ${STATICFLAG} ${LDFLAGS} ${SOURCE} ${OPTREPORTRECVWAIT} -DUSE_IRECV -o exe/recvwait.${COMPILER}.${STATIC}.${OUTNAME} ${EXTRAS}"
echo $cmd | sed 's/ \{1,\}/ /g'
(eval $cmd) &
pid5=$!

cmd="${MPICC} ${CFLAGS} ${STATICFLAG} ${LDFLAGS} ${OPREPORTPUT} osu_put_latency_mark.c -o exe/put.${COMPILER}.${STATIC}.${OUTNAME} ${EXTRAS}"
echo $cmd | sed 's/ \{1,\}/ /g'
(eval $cmd) &
pid6=$!

cmd="${MPICC} ${CFLAGS} ${STATICFLAG} ${LDFLAGS} ${OPREPORTPUTSYNC} osu_put_latency_mark.c -o exe/putsync.${COMPILER}.${STATIC}.${OUTNAME} ${EXTRAS}"
echo $cmd | sed 's/ \{1,\}/ /g'
(eval $cmd) &
pid7=$!

wait $pid0
rc0=$?
wait $pid1
rc1=$?
wait $pid2
rc2=$?
wait $pid3
rc3=$?
wait $pid4
rc4=$?
wait $pid5
rc5=$?
wait $pid6
rc6=$?
wait $pid7
rc7=$?

if [ $rc0 -eq 0 ] && [ $rc1 -eq 0 ] && [ $rc2 -eq 0 ] && [ $rc3 -eq 0 ] && [ $rc4 -eq 0 ] && [ $rc5 -eq 0 ] && [ $rc6 -eq 0 ] && [ $rc7 -eq 0 ]; then
    exit 0
else
    exit 1
fi
