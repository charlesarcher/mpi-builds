#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi>"
    exit
fi

COMPILER=$1
SHMEMDIR=$(pwd)/portals-shmem-svn-git
INSTALL_DIR=$(pwd)/../install/${COMPILER}
BUILD_HOST=i386-pc-linux-gnu
BUILD_TARGET=i686-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu
THREAD_LEVEL=default

STAGEDIR=$(pwd)/stage/${COMPILER}
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
        COMPILERPATH=/path/to/intel
        export LD=ld
        export CC=icc
        export CXX=icpc
        export F77=ifort
        export FC=ifort
        ;;
    gnu )
        export LD=ld
        export CC=gcc
        export CXX=g++
        export F77=gfortran
        export FC=gfortran
        ;;
    * )
        echo "Unknown compiler type"
        exit
esac


export CFLAGS=
export CXXFLAGS=
export LDFLAGS=-lm
export AUTOCONFTOOLS=/home/cjarcher/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:${COMPILERPATH}:/bin:/usr/bin
export SFIDIR=${INSTALL_DIR}
export PORTALS=${INSTALL_DIR}
export PMI=${INSTALL_DIR}

# BUILD
if [ 1 -eq 0 ] ; then
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
if [ ! -f ./Makefile ] ; then                                     \
    ${SHMEMDIR}/configure                                         \
    --prefix=${INSTALL_DIR}                                       \
    --mandir=${INSTALL_DIR}/man                                   \
    --host=${BUILD_HOST}                                          \
    --target=${BUILD_TARGET}                                      \
    --build=${BUILD_BUILD}                                        \
    --with-portals4=${PORTALS}                                    \
    --with-pmi=${PMI}                                             \
    --disable-fortran                                             \
    ; fi
else
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
if [ ! -f ./Makefile ] ; then                                     \
    ${SHMEMDIR}/configure                                         \
    --prefix=${INSTALL_DIR}                                       \
    --mandir=${INSTALL_DIR}/man                                   \
    --host=${BUILD_HOST}                                          \
    --target=${BUILD_TARGET}                                      \
    --build=${BUILD_BUILD}                                        \
    --with-pmi=${PMI}                                             \
    --with-sfi=${SFIDIR}                                          \
    --disable-fortran                                             \
    ; fi
fi
make -j8
make install
