#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi>"
    exit
fi

COMPILER=$1
PORTALSDIR=$(pwd)/portals4
INSTALL_DIR=$(pwd)/../install/${COMPILER}/portals
export EVDIR=$(pwd)/../install/${COMPILER}/ev
THREAD_LEVEL=default

export AUTOCONFTOOLS=/home/cjarcher/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:/bin:/usr/bin


STAGEDIR=$(pwd)/stage/${COMPILER}/portals
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
        export LD=ld
        export CC="icc"
        export CXX=icpc
        export F77=ifort
        export FC=ifort
        export EXTRA_OPT="-ipo -axAVX -march=corei7 -std=c99"
        export AR=xiar
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

#export CFLAGS="-g -O3 -DNDEBUG -finline-functions -fno-strict-aliasing ${EXTRA_OPT}"
#export CXXFLAGS="-g -O3 -DNDEBUG -finline-functions -fno-strict-aliasing ${EXTRA_OPT}"

export CFLAGS="-O0 -g"
export CXXFLAGS="-O0 -g"
export LDFLAGS="-lm"

#Cross compiling?
#BUILD_HOST=i386-pc-linux-gnu
#BUILD_TARGET=i686-pc-linux-gnu
#BUILD_BUILD=i686-pc-linux-gnu
#    --host=${BUILD_HOST}                                          \
#    --target=${BUILD_TARGET}                                      \
#    --build=${BUILD_BUILD}                                        \


# BUILD
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
if [ ! -f ./Makefile ] ; then                                     \
    ${PORTALSDIR}/configure                                       \
    --prefix=${INSTALL_DIR}                                       \
    --mandir=${INSTALL_DIR}/man                                   \
    --with-ev=${EVDIR}                                            \
    --enable-transport-ib                                         \
    --disable-transport-shmem                                     \
    --disable-transport-udp                                       \
    --enable-cross-cmpxchg16b                                     \
    ; fi

make -j8
make install
