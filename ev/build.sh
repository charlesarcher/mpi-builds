#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi>"
    exit
fi

COMPILER=$1
EVDIR=$(pwd)/libev-4.15
INSTALL_DIR=$(pwd)/../install/${COMPILER}/ev
BUILD_HOST=i386-pc-linux-gnu
BUILD_TARGET=i686-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu
THREAD_LEVEL=default

export AUTOCONFTOOLS=/home/cjarcher/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:/bin:/usr/bin
STAGEDIR=$(pwd)/stage/${COMPILER}/ev

case $COMPILER in
    pgi )
        export LD=ld
        export CC=pgc
        export CXX=pgc++
        export F77=pgf77
        export FC=pgfortran
        ;;
    intel )
        echo "Using Intel compiler"
        . /opt/intel/bin/compilervars.sh intel64
        export LD=ld
        export CC=icc
        export CXX=icpc
        export F77=ifort
        export FC=ifort
        export AR=xiar
        export EXTRA_OPT=-ipo
        ;;
    gnu )
        export LD=ld
        export CC=gcc
        export CXX=g++
        export F77=gfortran
        export FC=gfortran
        ;;
    clang )
        export LD=ld
        export CC=clang
        export CXX=clang++
        export F77=gfortran
        export FC=gfortran
        export EXTRA_OPT=""
        ;;
    * )
        echo "Unknown compiler type"
        exit
esac


export CFLAGS="-O3 -DNDEBUG -finline-functions -fno-strict-aliasing ${EXTRA_OPT}"
export CXXFLAGS="-O3 -DNDEBUG -finline-functions -fno-strict-aliasing ${EXTRA_OPT}"

# BUILD
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
if [ ! -f ./Makefile ] ; then                                     \
    ${EVDIR}/configure                                            \
    --prefix=${INSTALL_DIR}                                       \
    --mandir=${INSTALL_DIR}/man                                   \
    --host=${BUILD_HOST}                                          \
    --target=${BUILD_TARGET}                                      \
    --build=${BUILD_BUILD}                                        \
    ; fi

make -j8
make install
