#!/bin/sh

if [ $# -lt 2 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi> <mvapich|mvapich-ib|netmod-ofi-base|ch4_base_tpo|ch4_psm2|ch4|impi|ompi|ompi_stock|mvapich_stock>"
    exit
fi

COMPILER=$1
MPI=$2
OSUDIR=$(pwd)/osu-micro-benchmarks-5.3
INSTALL_DIR=$(pwd)/../install/${COMPILER}/osu/${MPI}
BUILD_HOST=i386-pc-linux-gnu
BUILD_TARGET=i686-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu
THREAD_LEVEL=default

export AUTOCONFTOOLS=/home/cjarcher/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:/bin:/usr/bin

if [ -e /opt/rh/devtoolset-3/enable ]; then
    . /opt/rh/devtoolset-3/enable
fi

case $MPI in
    mvapich_base )
        MPIBASE=/home/cjarcher/code/install/${COMPILER}/mvapich-optimized-base
        ;;
    ch3_base_ts )
        MPIBASE=/home/cjarcher/code/install/${COMPILER}/optimized-ch3-ts-inline-ep-indirect-embedded-map-exclusive-tagged-base
        ;;
    ch3_base_tg )
        MPIBASE=/home/cjarcher/code/install/${COMPILER}/optimized-ch3-tg-inline-ep-indirect-embedded-map-exclusive-tagged-base
        ;;
    ch4_base_tpo )
        MPIBASE=/home/cjarcher/code/install/${COMPILER}/optimized-ofi-tpo-inline-ep-indirect-embedded-map-exclusive-tagged-base
        ;;
    ch4_debug_tpo )
        MPIBASE=/home/cjarcher/code/install/${COMPILER}/debug-ofi-tpo-inline-ep-indirect-embedded-map-exclusive-tagged-base
        ;;
    ch4_base_ts )
        MPIBASE=/home/cjarcher/code/install/${COMPILER}/optimized-ofi-ts-inline-ep-indirect-embedded-map-exclusive-tagged-base
        ;;
    ch4_base_tg )
        MPIBASE=/home/cjarcher/code/install/${COMPILER}/optimized-ofi-tg-inline-ep-indirect-embedded-map-exclusive-tagged-base
        ;;
    ompi_base )
        MPIBASE=/home/cjarcher/code/install/${COMPILER}/openmpi-optimized-base
        ;;
    impi_base )
        MPIBASE=/opt/intel/impi/2017/intel64
        ;;
    ompi_stock )
        case $COMPILER in
            gnu )
                MPIBASE=/usr/mpi/gcc/openmpi-1.10.2-hfi
                ;;
            intel )
                MPIBASE=/usr/mpi/intel/openmpi-1.10.2-hfi
                ;;
            * )
                echo "Unknown compiler type for ompi_stock"
                exit
        esac
        ;;
    mvapich_stock )
        case $COMPILER in
            gnu )
                MPIBASE=/usr/mpi/gcc/mvapich2-2.1-hfi
                ;;
            intel )
                MPIBASE=/usr/mpi/intel/mvapich2-2.1-hfi
                ;;
            * )
                echo "Unknown compiler type for ompi_stock"
                exit
        esac
        ;;
    * )
        echo "Unknown compiler type"
        exit
esac

MPICC_NAME=mpicc
MPICXX_NAME=mpicxx
MPIF77_NAME=mpifort
MPIFC_NAME=mpifort
STAGEDIR=$(pwd)/stage/${COMPILER}/${MPI}

case $COMPILER in
    pgi )
        COMPILERPATH=/path/to/pgi
        export LD=ld
        export CC=pgc
        export CXX=pgc++
        export F77=pgf77
        export FC=pgfortran
        ;;
    intel )
        . ${HOME}/intel_compilervars.sh intel64
        . ${HOME}/code/setup_intel.sh
        export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | sed -e 's/\/opt\/intel\/compilers_and_libraries_2016.3.210\/linux\/mpi\/intel64\/lib//')
        export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | sed -e 's/\/opt\/intel\/compilers_and_libraries_2016.2.181\/linux\/mpi\/intel64\/lib//')
        if [ "${MPI}" = "impi_base" ]; then
            MPICC_NAME=mpiicc
            MPICXX_NAME=mpiicpc
        elif [ "${MPI}" = "mvapich_stock" ]; then
            EXTRA_LD_OPT="${EXTRA_LD_OPT} -Wl,--warn-unresolved-symbols"
            EXTRA_LD_DEBUG="${EXTRA_LD_DEBUG} -Wl,--warn-unresolved-symbols"
            EXTRA_OPT="${EXTRA_OPT} -Wl,--warn-unresolved-symbols"
            EXTRA_DEBUG="${EXTRA_DEBUG} -Wl,--warn-unresolved-symbols"
        fi

        ;;
    gnu )
        if [ -e /opt/rh/devtoolset-3/enable ]; then
            . /opt/rh/devtoolset-3/enable
        fi
        . ${HOME}/code/setup_gnu.sh
        ;;
    clang )
        if [ -e /opt/rh/devtoolset-3/enable ]; then
            . /opt/rh/devtoolset-3/enable
        fi
        . ${HOME}/code/setup_clang.sh
        ;;
    * )
        echo "Unknown compiler type"
        exit
esac

#MCMODEL="-mcmodel=large"
OPTFLAGS_COMMON="-Wall -ggdb -O3  ${MCMODEL} -DNDEBUG ${EXTRA_OPT}"
OPTLDFLAGS_COMMON="-O3 ${MCMODEL} ${EXTRA_LD_OPT}"
DEBUGFLAGS_COMMON="-Wall -ggdb ${MCMODEL} -O0 ${EXTRA_DEBUG}"
DEBUGLDFLAGS_COMMON="-O0 ${MCMODEL} ${EXTRA_LD_DEBUG}"
BUILDTYPE=optimized

echo $OPTFLAGS_COMMON
echo $EXTRA_OPT
case ${BUILDTYPE} in
    optimized)
        export CFLAGS=${OPTFLAGS_COMMON}
        export CXXFLAGS=${OPTFLAGS_COMMON}
        export LDFLAGS=${OPTLDFLAGS_COMMON}
        ;;
    debug)
        export CFLAGS=${DEBUGFLAGS_COMMON}
        export CXXFLAGS=${DEBUGFLAGS_COMMON}
        export LDFLAGS=${DEBUGLDFLAGS_COMMON}
        ;;
    *)
        echo "${OPTION}: Unknown optimization type:  use optimized|debug"
        exit 1
        ;;
esac

export LD=ld
export CC=${MPIBASE}/bin/${MPICC_NAME}
export CXX=${MPIBASE}/bin/${MPICXX_NAME}
export F77=${MPIBASE}/bin/${MPIF77_NAME}
export FC=${MPIBASE}/bin/${MPIFC_NAME}

# BUILD
printf "|%-30s|%-50s|\n" "------------------------------" "-------------------------------------------------"
printf "|%-30s|%-50s|\n" "Option"             "Value"
printf "|%-30s|%-50s|\n" "------------------------------" "-------------------------------------------------"
printf "|%-30s|%-50s|\n" "CC:"                    "${CC}"
printf "|%-30s|%-50s|\n" "CXX:"                   "${CXX}"
printf "|%-30s|%-50s|\n" "F77:"                   "${F77}"
printf "|%-30s|%-50s|\n" "FC:"                    "${FC}"
printf "|%-30s|%-50s|\n" "CFLAGS:"                "${CFLAGS}"
printf "|%-30s|%-50s|\n" "CXXFLAGS:"              "${CXXFLAGS}"
printf "|%-30s|%-50s|\n" "LDFLAGS:"               "${LDFLAGS}"
printf "|%-30s|%-50s|\n" "MPICHLIB_CFLAGS:"       "${MPICHLIB_CFLAGS}"
printf "|%-30s|%-50s|\n" "MPICHLIB_CXXFLAGS:"     "${MPICHLIB_CXXFLAGS}"
printf "|%-30s|%-50s|\n" "MPICHLIB_LDFLAGS:"      "${MPICHLIB_LDFLAGS}"
printf "|%-30s|%-50s|\n" "DEVICES:"               "${DEVICES}"
printf "|%-30s|%-50s|\n" "OFI_NETMOD_ARGS:" "${OFI_NETMOD_ARGS}"
printf "|%-30s|%-50s|\n" "LIBFABRICDIR:"          "${LIBFABRICDIR}"
printf "|%-30s|%-50s|\n" "SHARED_MEMORY:"         "${SHARED_MEMORY}"
printf "|%-30s|%-50s|\n" "BUILD_TYPE:"            "${BUILD_TYPE}"
printf "|%-30s|%-50s|\n" "BUILD_TAG:"             "${BUILD_TAG}"
printf "|%-30s|%-50s|\n" "BUILD_THREADLEVEL:"     "${BUILD_THREADLEVEL}"
printf "|%-30s|%-50s|\n" "BUILD_LOCKLEVEL:"       "${BUILD_LOCKLEVEL}"
printf "|%-30s|%-50s|\n" "BUILD_ALLOCATION:"      "${BUILD_ALLOCATION}"
printf "|%-30s|%-50s|\n" "MPICH2DIR:"             "${MPICH2DIR}"
printf "|%-30s|%-50s|\n" "INSTALL_DIR:"           "${INSTALL_DIR}"
printf "|%-30s|%-50s|\n" "STAGEDIR:"              "${STAGEDIR}"
printf "|%-30s|%-50s|\n" "PWD:"                   "${PWD}"
printf "|%-30s|%-50s|\n" "HOSTNAME:"              "${HOSTNAME}"
printf "|%-30s|%-50s|\n" "SCAN_BUILD:"            "${SCAN_BUILD}"
printf "|%-30s|%-50s|\n" "------------------------------" "-------------------------------------------------"
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
if [ ! -f ./Makefile ] ; then                                     \
    ${OSUDIR}/configure                                           \
    --prefix=${INSTALL_DIR}                                       \
    --mandir=${INSTALL_DIR}/man                                   \
    --host=${BUILD_HOST}                                          \
    --target=${BUILD_TARGET}                                      \
    --build=${BUILD_BUILD}                                        \
    ; fi

cd mpi && make -j8

