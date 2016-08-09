#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi>"
    exit
fi

#MPICH2DIR=$(pwd)/ssg_sfi-libfabric
COMPILER=$1
MPICH2DIR=$(pwd)/ssg_sfi-mpich
INSTALL_DIR=$(pwd)/../install/${COMPILER}
THREAD_LEVEL=default
STAGEDIR=$(pwd)/stage/${COMPILER}
export AUTOCONFTOOLS=/home/cjarcher/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:${COMPILERPATH}:/bin:/usr/bin



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

export CFLAGS="-O3 -DNDEBUG -finline-functions -fno-strict-aliasing -ipo"
export CXXFLAGS="-O3 -DNDEBUG -finline-functions -fno-strict-aliasing -ipo"
#export CFLAGS="-ipo -O3 -DNDEBUG -finline-functions -fno-strict-aliasing"
#export CXXFLAGS="-ipo -O3 -DNDEBUG -finline-functions -fno-strict-aliasing"
#export CFLAGS="-O0"
#export CXXFLAGS="-O0"
export LDFLAGS=""

export PM=hydra
export DEVICES=ch3:nemesis:ib
export PORTALS4=${INSTALL_DIR}
export OF2=${INSTALL_DIR}

# BUILD
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}

#Cross
BUILD_HOST=i386-pc-linux-gnu
BUILD_TARGET=i686-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu


if [ 1 -eq 1 ] ; then
    if [ ! -f ./Makefile ] ; then                                     \
        echo " ====== BUILDING MPICH2 Optimized Library =======";     \
        MPILIBNAME="mpi"                                              \
        MPICXXLIBNAME="mpigc4"                                        \
        ${MPICH2DIR}/configure                                        \
        --host=${BUILD_HOST}                                          \
        --target=${BUILD_TARGET}                                      \
        --build=${BUILD_BUILD}                                        \
        --with-cross=${MPICH2DIR}/src/mpid/pamid/cross/pe8            \
        --enable-cache                                                \
        --disable-rpath                                               \
        --disable-versioning                                          \
        --prefix=${INSTALL_DIR}                                       \
        --mandir=${INSTALL_DIR}/man                                   \
        --htmldir=${INSTALL_DIR}/www                                  \
        --enable-dependencies                                         \
        --enable-g=none                                               \
        --with-pm=${PM}                                               \
        --with-device=${DEVICES}                                      \
        --enable-romio=yes                                            \
        --enable-f77=yes                                              \
        --enable-fc=yes                                               \
        --with-file-system=ufs+nfs                                    \
        --enable-timer-type=linux86_cycle                             \
        --enable-threads=single                                       \
        --enable-thread-cs=global                                     \
        --with-fwrapname=mpigf                                        \
        --with-mpe=no                                                 \
        --with-smpcoll=yes                                            \
        --without-valgrind                                            \
        --enable-timing=none                                          \
        --with-aint-size=8                                            \
        --with-assert-level=0                                         \
        --enable-shared                                               \
        --enable-sharedlibs=gcc                                       \
        --enable-dynamiclibs                                          \
        --disable-debuginfo                                           \
        --enable-fast=all,O3                                          \
        ; fi
else
    if [ ! -f Makefile ] ; then                                     \
        echo " ====== BUILDING MPICH2 Debug Library =======";       \
        MPILIBNAME="mpi"                                            \
        MPICXXLIBNAME="mpigc4"                                      \
        MPICH2LIB_CFLAGS="${CFLAGS} -DMPIDI_TRACE"                  \
        ${MPICH2DIR}/configure                                      \
        --host=${BUILD_HOST}                                        \
        --target=${BUILD_TARGET}                                    \
        --build=${BUILD_BUILD}                                      \
        --with-cross=${MPICH2DIR}/src/mpid/pamid/cross/pe8          \
        --enable-cache                                              \
        --disable-rpath                                             \
        --disable-versioning                                        \
        --prefix=${INSTALL_DIR}                                     \
        --mandir=${INSTALL_DIR}/man                                 \
        --htmldir=${INSTALL_DIR}/www                                \
        --enable-dependencies                                       \
        --enable-g=all                                              \
        --with-pm=${PM}                                             \
        --with-device=${DEVICES}                                    \
        --enable-romio=yes                                          \
        --enable-f77=yes                                            \
        --enable-fc=yes                                             \
        --with-file-system=ufs+nfs                                  \
        --enable-timer-type=linux86_cycle                           \
        --enable-threads=single                                     \
        --enable-thread-cs=global                                   \
        --with-fwrapname=mpigf                                      \
        --with-mpe=no                                               \
        --with-smpcoll=yes                                          \
        --without-valgrind                                          \
        --enable-timing=runtime                                     \
        --with-aint-size=8                                          \
        --with-assert-level=2                                       \
        --enable-shared                                             \
        --enable-sharedlibs=gcc                                     \
        --enable-dynamiclibs                                        \
        --disable-debuginfo                                         \
        --enable-fast=none                                          \
        ; fi
fi


make V=0 -j32 &&                                   \
echo "Fortran Fixup" &&                           \
cd ${STAGEDIR} && ${CC} ${CFLAGS} ${LDFLAGS}      \
    -shared src/binding/fortran/use_mpi/.libs/*.o \
            src/binding/fortran/mpif_h/.libs/*.o  \
    -o      lib/.libs/libmpigf.so &&              \
echo "Fortran Fixup Done" &&                      \
make V=0 install -j32
