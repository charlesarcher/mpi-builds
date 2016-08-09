#!/bin/sh


if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi> <opt>"
    exit
fi

LIBRARY=$2
if [ "$LIBRARY" == "opt" ]; then
    LIBRARY="opt"
elif [ "$LIBRARY" == "" ]; then
    LIBRARY="debug"
elif [ "$LIBRARY" == "debug" ]; then
    LIBRARY="debug"
else
    echo "Invalid opt set, use <debug|opt>"
    exit
fi

COMPILER=$1
MPICH2DIR=$(pwd)/ssg_sfi-mpich
INSTALL_DIR=$(pwd)/../install/${COMPILER}/netmod-${LIBRARY}
THREAD_LEVEL=default
STAGEDIR=$(pwd)/stage/${COMPILER}/netmod-${LIBRARY}
export OFIDIR=$(pwd)/../install/${COMPILER}/ofi
export AUTOCONFTOOLS=${HOME}/tools/x86/bin
export PATH=/bin:/usr/bin
export PATH=/opt/local/bin:/opt/local/sbin:$PATH


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
        . /opt/intel/bin/compilervars.sh intel64
        export AR=xiar
        export LD=ld
        export CC=icc
        export CXX=icpc
        export F77=ifort
        export FC=ifort
        EXTRA_OPT="-ipo"
        EXTRA_OPT="${EXTRA_OPT} -no-inline-factor"
        EXTRA_OPT="${EXTRA_OPT} -inline-forceinline"
        EXTRA_OPT="${EXTRA_OPT} -inline-max-size=10000"
        EXTRA_OPT="${EXTRA_OPT} -inline-min-size=10000"
        EXTRA_OPT="${EXTRA_OPT} -inline-max-total-size=200000"
        EXTRA_OPT="${EXTRA_OPT} -inline-max-per-routine=200000"
        EXTRA_OPT="${EXTRA_OPT} -inline-max-per-compile=200000"
        export EXTRA_OPT
        ;;
    gnu )
        if [ -e /opt/rh/devtoolset-3/enable ]; then
            . /opt/rh/devtoolset-3/enable
        fi
        export LD=ld
        export CC=gcc
        export CXX=g++
        export F77=gfortran
        export FC=gfortran
#	export EXTRA_LDOPT=-flto
#	export EXTRA_OPT=-flto
        ;;
    clang )
#        export EXTRA_OPT="-flto"
        export LD=ld
        export CC="clang"
        export CXX="clang++"
        export F77=gfortran
        export FC=gfortran
        ;;
    * )
        echo "Unknown compiler type"
        exit
esac

#export CFLAGS="-gdwarf-2 -O3 -DNDEBUG -fomit-frame-pointer -finline-functions -fno-strict-aliasing ${EXTRA_OPT}"
#export CXXFLAGS="-gdwarf-2 -O3 -DNDEBUG -fomit-frame-pointer -finline-functions -fno-strict-aliasing ${EXTRA_OPT}"
export CFLAGS="-O0 -gdwarf-2 -Wall -Wextra"
export CXXFLAGS="-O0 -gdwarf-2 -Wall -Wextra"
export LDFLAGS="${EXTRA_LDOPT}"
export PM=hydra
export DEVICES=ch3:nemesis:tcp,ofi

# BUILD
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}

#Cross
BUILD_HOST=i386-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu
BUILD_THREADLEVEL=multiple
BUILD_LOCKLEVEL=global
BUILD_ALLOCATION=default
#DISABLE_SHM="--enable-nemesis-dbg-nolocal --disable-nemesis-shm-collectives"
export CROSSFILE=${MPICH2DIR}/src/mpid/pamid/cross/pe8
export CROSSFILE=${MPICH2DIR}/src/mpid/adi/cross/gcc-linux-x86-8

if [ "$LIBRARY" == "opt" ]; then
    if [ ! -f ./Makefile ] ; then                                     \
        echo " ====== BUILDING MPICH2 Optimized Library =======";     \
                  MPILIBNAME="mpi"                                              \
                  MPICXXLIBNAME="mpigc4"                                        \
                  ${MPICH2DIR}/configure                                        \
                  --prefix=${INSTALL_DIR}                                       \
                  --mandir=${INSTALL_DIR}/man                                   \
                  --htmldir=${INSTALL_DIR}/www                                  \
                  --enable-dependencies                                         \
                  --enable-g=none                                               \
                  --with-pm=${PM}                                               \
                  --with-device=${DEVICES}                                      \
                  --with-ofi=${OFIDIR}                                          \
                  --enable-romio=yes                                            \
                  --enable-f77=yes                                              \
                  --enable-fc=yes                                               \
                  --with-file-system=ufs+nfs                                    \
                  --enable-timer-type=mach_absolute_time                        \
                  --enable-threads=${BUILD_THREADLEVEL}                         \
                  --enable-thread-cs=${BUILD_LOCKLEVEL}                         \
                  --enable-handle-allocation=${BUILD_ALLOCATION}                \
                  --with-smpcoll=yes                                            \
                  --enable-timing=none                                          \
                  --with-assert-level=0                                         \
                  --enable-shared=yes                                           \
                  --enable-sharedlibs=osx-gcc                                   \
                  --enable-static=yes                                           \
                  --disable-debuginfo                                           \
                  --enable-error-checking=no                                    \
                  --enable-error-messages=all                                   \
                  --enable-fast=all,O3                                          \
                  ${DISABLE_SHM}                                                \
        ; fi
else
    echo " ====== BUILDING MPICH2 Debug Library =======";       \
    if [ ! -f Makefile ] ; then                                     \
        MPILIBNAME="mpi"                                            \
                  ${MPICH2DIR}/configure                                      \
                  --prefix=${INSTALL_DIR}                                     \
                  --mandir=${INSTALL_DIR}/man                                 \
                  --htmldir=${INSTALL_DIR}/www                                \
                  --enable-g=all                                              \
                  --with-pm=${PM}                                             \
                  --with-device=${DEVICES}                                    \
                  --with-ofi=${OFIDIR}                                        \
                  --enable-romio=yes                                          \
                  --enable-fc=yes                                             \
                  --enable-f77=yes                                            \
                  --with-file-system=ufs+nfs                                  \
                  --enable-timer-type=mach_absolute_time                      \
                  --enable-threads=${BUILD_THREADLEVEL}                       \
                  --enable-thread-cs=${BUILD_LOCKLEVEL}                       \
                  --enable-handle-allocation=${BUILD_ALLOCATION}              \
                  --with-smpcoll=yes                                          \
                  --enable-shared=yes                                         \
                  --enable-sharedlibs=osx-gcc                                 \
                  --enable-static=yes                                         \
                  --enable-error-checking=all                                 \
                  --enable-error-messages=all                                 \
                  --enable-fast=none                                          \
                  ${DISABLE_SHM}                                              \
        ; fi
fi


make V=0 -j4 && make V=0 install -j4
