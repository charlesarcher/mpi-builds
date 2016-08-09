#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi>"
    exit
fi

COMPILER=$1
SHMEMDIR=$(pwd)/ssg_sfi-shmem
INSTALL_DIR=$(pwd)/../install/${COMPILER}
BUILD_HOST=i386-pc-linux-gnu
BUILD_TARGET=i686-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu
THREAD_LEVEL=default
export AUTOCONFTOOLS=${HOME}/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:${COMPILERPATH}:/bin:/usr/bin



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
        . /opt/intel/bin/compilervars.sh intel64
        export AR=xiar
        export LD=ld
        export CC=icc
        export CXX=icpc
        export F77=ifort
        export FC=ifort
        export EXTRA_OPT="-finline-limit=2097152 -ipo"
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


#export CFLAGS="-O3 -DNDEBUG -finline-functions -fno-strict-aliasing -fomit-frame-pointer ${EXTRA_OPT}"
#export CXXFLAGS="-O3 -DNDEBUG -finline-functions -fno-strict-aliasing -fomit-frame-pointer ${EXTRA_OPT}"
export CFLAGS="-O0 -g"
export CXXFLAGS="-O0 -g"
export LDFLAGS=-lm
export AUTOCONFTOOLS=/home/cjarcher/tools/x86/bin
export SFIDIR=${INSTALL_DIR}
export PORTALS=${INSTALL_DIR}
#export PMI=/home/luom/mv2/mvapich2-2.0b/build
#export PMILIBNAME=mpich
#export PMI=${INSTALL_DIR}

echo ${CFLAGS}
echo ${CXXFLAGS}


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
    --with-sfi=${SFIDIR}                                          \
    --disable-fortran                                             \
    ; fi
fi
make -j8
make install
