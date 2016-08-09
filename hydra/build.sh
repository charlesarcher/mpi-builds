#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi>"
    exit
fi

COMPILER=$1
MPICH2DIR=$(pwd)/hydra-3.1.1
INSTALL_DIR=$(pwd)/../install/${COMPILER}
INSTALL_DIR=~/code/install/gnu.debug-adi-ts
BUILD_HOST=i386-pc-linux-gnu
BUILD_TARGET=i686-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu
THREAD_LEVEL=default
export AUTOCONFTOOLS=/home/cjarcher/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:/bin:/usr/bin


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


export CFLAGS=""
export CXXFLAGS=""
export LDFLAGS=""
export PM=hydra:mpd:gforker
export DEVICES=ch3:nemesis:tcp

# BUILD
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}

#        --host=${BUILD_HOST}                                          \
#        --target=${BUILD_TARGET}                                      \
#        --build=${BUILD_BUILD}                                        \
#        --with-cross=${MPICH2DIR}/src/mpid/pamid/cross/pe8            \


if [ 0 -eq 1 ] ; then
    if [ ! -f ./Makefile ] ; then                                     \
        echo " ====== BUILDING MPICH2 Optimized Library =======";     \
        ${MPICH2DIR}/configure                                        \
        --enable-cache                                                \
        --disable-rpath                                               \
        --disable-versioning                                          \
        --prefix=${INSTALL_DIR}                                       \
        --mandir=${INSTALL_DIR}/man                                   \
        --htmldir=${INSTALL_DIR}/www                                  \
        --enable-dependencies                                         \
        --enable-g=none                                               \
        ; fi
else
    if [ ! -f Makefile ] ; then                                     \
        echo " ====== BUILDING MPICH2 Debug Library =======";       \
        ${MPICH2DIR}/configure                                      \
        --enable-cache                                              \
        --disable-rpath                                             \
        --disable-versioning                                        \
        --prefix=${INSTALL_DIR}                                     \
        --mandir=${INSTALL_DIR}/man                                 \
        --htmldir=${INSTALL_DIR}/www                                \
        --enable-dependencies                                       \
        ; fi
fi




make -j8

cd ${STAGEDIR} && ${CC} ${CFLAGS} ${LDFLAGS}                  \
    -shared src/binding/f77/.libs/*.o                         \
    src/binding/f90/.libs/*.o                                 \
    -o      lib/.libs/libmpigf.so

make install
