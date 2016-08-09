#!/bin/bash
trap "kill 0" SIGINT

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <compile|run>"
    exit
fi

PHASE=$1

yell()      { echo "$0: $*" >&2; }
yellspace() { echo "     -----> $0: $*" >&2; }
die()       { yell "$*"; exit 111; }
try()       { "$@" || die "cannot $*"; }

declare -A MPIEXEC_FLAVORS
declare -A MPI_FLAVORS
declare -A MPI_OPTIONS
declare -A MPI_ENV
MPI_FLAVORS=()
MPI_OPTIONS=()
MPI_ENV=()
BINDIR_BASE=/home/cjarcher/code/install

function build_table()
{
    local COMPILER=$1
    if [ "$1" = "gnu" ]; then
        SYSTEM_COMPILER=gcc
    else
        SYSTEM_COMPILER=$1
    fi
    MPIEXEC_FLAVORS=(
        ["mvapich_psm2"]="${BINDIR_BASE}/${COMPILER}/mvapich-optimized-base/bin/mpiexec.hydra"
        ["mvapich_system_psm2"]="/usr/mpi/${SYSTEM_COMPILER}/mvapich2-2.1-hfi/bin/mpirun"
        ["ch3_ofi_psm2_ts"]="${BINDIR_BASE}/${COMPILER}/optimized-ch3-ts-inline-ep-indirect-embedded-map-disabled-tagged-base/bin/mpiexec.hydra"
        ["ch3_ofi_psm2_tg"]="${BINDIR_BASE}/${COMPILER}/optimized-ch3-tg-inline-ep-indirect-embedded-map-disabled-tagged-base/bin/mpiexec.hydra"
        ["ch4_ofi_psm2_tpo"]="${BINDIR_BASE}/${COMPILER}/optimized-ofi-tpo-inline-ep-indirect-embedded-map-disabled-tagged-base/bin/mpiexec.hydra"
        ["ch4_ofi_psm2_tg"]="${BINDIR_BASE}/${COMPILER}/optimized-ofi-tg-inline-ep-indirect-embedded-map-disabled-tagged-base/bin/mpiexec.hydra"
        ["ch4_ofi_psm2_ts"]="${BINDIR_BASE}/${COMPILER}/optimized-ofi-ts-inline-ep-indirect-embedded-map-disabled-tagged-base/bin/mpiexec.hydra"
        ["openmpi_ofi_psm2"]="${BINDIR_BASE}/${COMPILER}/openmpi-optimized-base/bin/mpirun"
		["openmpi_system_psm2"]="/usr/mpi/${SYSTEM_COMPILER}/openmpi-1.10.2-hfi/bin/mpirun"
        ["impi_psm2"]="/opt/intel/impi/2017/intel64/bin/mpiexec.hydra"
        ["impi_ofi_psm2"]="/opt/intel/impi/2017/intel64/bin/mpiexec.hydra"
    )

    MPI_FLAVORS=(
        ["mvapich_psm2"]="mvapich-optimized-base"
        ["mvapich_system_psm2"]="/usr/mpi/${SYSTEM_COMPILER}/mvapich2-2.1-hfi"
        ["ch3_ofi_psm2_ts"]="optimized-ch3-ts-inline-ep-indirect-embedded-map-disabled-tagged-base"
        ["ch3_ofi_psm2_tg"]="optimized-ch3-tg-inline-ep-indirect-embedded-map-disabled-tagged-base"
        ["ch4_ofi_psm2_tpo"]="optimized-ofi-tpo-inline-ep-indirect-embedded-map-disabled-tagged-base"
        ["ch4_ofi_psm2_tg"]="optimized-ofi-tg-inline-ep-indirect-embedded-map-disabled-tagged-base"
        ["ch4_ofi_psm2_ts"]="optimized-ofi-ts-inline-ep-indirect-embedded-map-disabled-tagged-base"
        ["openmpi_ofi_psm2"]="openmpi-optimized-base"
        ["openmpi_system_psm2"]="/usr/mpi/${SYSTEM_COMPILER}/openmpi-1.10.2-hfi"
        ["impi_psm2"]="/opt/intel/impi/2017/intel64"
        ["impi_ofi_psm2"]="/opt/intel/impi/2017/intel64"
    )
    MPI_OPTIONS=(
        ["mvapich_psm2"]="-launcher ssh -hosts ${HOSTS} -ppn 1"
        ["mvapich_system_psm2"]="-launcher ssh -hosts ${HOSTS} -ppn 1"
        ["ch3_ofi_psm2_ts"]="-launcher ssh -hosts ${HOSTS} -ppn 1"
        ["ch3_ofi_psm2_tg"]="-launcher ssh -hosts ${HOSTS} -ppn 1"
        ["ch4_ofi_psm2_ts"]="-launcher ssh -hosts ${HOSTS} -ppn 1"
        ["ch4_ofi_psm2_tpo"]="-launcher ssh -hosts ${HOSTS} -ppn 1"
        ["ch4_ofi_psm2_tg"]="-launcher ssh -hosts ${HOSTS} -ppn 1"
        ["openmpi_ofi_psm2"]="--quiet --mca mtl ofi --mca pml cm -hostfile host.list -x PSM_PKEY=0x8001"
        ["openmpi_system_psm2"]="--quiet --mca mtl psm2 --mca pml cm -host ${HOSTS} -x PSM_PKEY=0x8001"
        ["impi_psm2"]="-launcher ssh -hosts ${HOSTS} -ppn 1"
        ["impi_ofi_psm2"]="-launcher ssh -hosts ${HOSTS} -ppn 1"
    )
    MPI_ENV=(
        ["mvapich_psm2"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
        ["mvapich_system_psm2"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
        ["ch3_ofi_psm2_ts"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH} MPICH_NEMESIS_NETMOD=ofi"
        ["ch3_ofi_psm2_tg"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH} MPICH_NEMESIS_NETMOD=ofi"
        ["ch4_ofi_psm2_ts"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
        ["ch4_ofi_psm2_tpo"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
        ["ch4_ofi_psm2_tg"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
        ["openmpi_ofi_psm2"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
        ["openmpi_system_psm2"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
        ["impi_psm2"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH} I_MPI_OFI_LIBRARY=${BINDIR_BASE}/${COMPILER}/ofi-optimized-base/lib/libfabric.so I_MPI_FABRICS=tmi TMI_CONFIG=/home/cjarcher/tmi.config  I_MPI_PLATFORM=bdw"
        ["impi_ofi_psm2"]="LD_LIBRARY_PATH=${LD_LIBRARY_PATH} I_MPI_OFI_LIBRARY=${BINDIR_BASE}/${COMPILER}/ofi-optimized-base/lib/libfabric.so I_MPI_FABRICS=ofi I_MPI_PLATFORM=bdw"
    )
}

#COMPILERS="gnu intel clang"
COMPILERS="intel gnu"
#LIBTYPES="dynamic static"
LIBTYPES="dynamic"
SERIES="openmpi_system_psm2 openmpi_ofi_psm2 mvapich_system_psm2 mvapich_psm2 ch3_ofi_psm2_ts ch3_ofi_psm2_tg ch4_ofi_psm2_ts ch4_ofi_psm2_tpo ch4_ofi_psm2_tg impi_psm2 impi_ofi_psm2"
#SERIES=ch4_ofi_psm2_tpo
HOSTS="f055,f056"
BENCHMARKS="isend send sendwait recvwait irecv recv put putsync"

case ${PHASE} in
    compile)
        rm -f exe/*
        rm -f optlog/*
        for LIBTYPE in $LIBTYPES; do
            echo "COMPILING $LIBTYPE builds"
            for COMPILER in ${COMPILERS}; do
                build_table ${COMPILER}
                for MPI in $SERIES; do
                    cmd=$(echo sh compile.sh ${COMPILER} ${MPI_FLAVORS["${MPI}"]}  ${LIBTYPE} ${MPI})
                    echo "     $cmd"
                    (eval $cmd >/dev/null 2>&1 || yellspace "FATAL: Command was '$cmd'") &
                done
            done
            wait
        done
        ;;
    run)
        rm -f sdelog/*
        for LIBTYPE in $LIBTYPES; do
            echo "RUNNING $LIBTYPE builds"
            for COMPILER in ${COMPILERS}; do
                echo ============== Running ${COMPILER} ==============
                for MPI in $SERIES; do
                    if [ "${MPI}" = "mvapich_system_psm2" ] || [ "${MPI}" = "openmpi_system_psm2" ]; then
                        unset LD_LIBRARY_PATH
                        . /opt/intel/composer_xe_2015.3.187/bin/compilervars.sh intel64
                    else
                        unset LD_LIBRARY_PATH
                        . ${HOME}/intel_compilervars.sh intel64
                        LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | sed -e 's/\/opt\/intel\/compilers_and_libraries_2016.3.210\/linux\/mpi\/intel64\/lib//')
                        LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | sed -e 's/\/opt\/intel\/compilers_and_libraries_2016.2.181\/linux\/mpi\/intel64\/lib//')
                    fi
                    build_table ${COMPILER}
                    for BENCHMARK in $BENCHMARKS; do
                        MPIEXEC="${MPIEXEC_FLAVORS["${MPI}"]}"
                        if [ "${BENCHMARK}" = "put" ]; then
                            cmd=$(echo  ${MPI_ENV["${MPI}"]} ${MPIEXEC} ${MPI_OPTIONS["${MPI}"]} -n 2 ./sdeput.sh ${BENCHMARK}.${COMPILER}.${LIBTYPE}.${MPI})
                        elif [ "${BENCHMARK}" = "putsync" ]; then
                            cmd=$(echo  ${MPI_ENV["${MPI}"]} ${MPIEXEC} ${MPI_OPTIONS["${MPI}"]} -n 2 ./sdeputsync.sh ${BENCHMARK}.${COMPILER}.${LIBTYPE}.${MPI})
                        elif [ "${BENCHMARK}" = "recv" ] || [ "${BENCHMARK}" = "irecv" ]; then
                            cmd=$(echo  ${MPI_ENV["${MPI}"]} ${MPIEXEC} ${MPI_OPTIONS["${MPI}"]} -n 2 ./sderecv.sh ${BENCHMARK}.${COMPILER}.${LIBTYPE}.${MPI})
                        elif [ "${BENCHMARK}" = "sendwait" ]; then
                            cmd=$(echo  ${MPI_ENV["${MPI}"]} ${MPIEXEC} ${MPI_OPTIONS["${MPI}"]} -n 2 ./sdesendwait.sh ${BENCHMARK}.${COMPILER}.${LIBTYPE}.${MPI})
                        elif [ "${BENCHMARK}" = "recvwait" ]; then
                            cmd=$(echo  ${MPI_ENV["${MPI}"]} ${MPIEXEC} ${MPI_OPTIONS["${MPI}"]} -n 2 ./sderecvwait.sh ${BENCHMARK}.${COMPILER}.${LIBTYPE}.${MPI})
                        else
                            cmd=$(echo  ${MPI_ENV["${MPI}"]} ${MPIEXEC} ${MPI_OPTIONS["${MPI}"]} -n 2 ./sde.sh ${BENCHMARK}.${COMPILER}.${LIBTYPE}.${MPI})
                        fi
                        echo "        | Running ${BENCHMARK}.${COMPILER}.${LIBTYPE}.${MPI} =============="
                        eval $cmd >/dev/null 2>&1 || yellspace "FATAL: Command was '$cmd'"
                    done
                done
             done
        done
        ;;
    *)
        echo "Invalid phase:  <run|compile>"
        exit 1
        ;;
esac
