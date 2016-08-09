#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi> <opt>"
    exit 1
fi

LIBRARY=$2
if [ "$LIBRARY" == "optimized" ]; then
    LIBRARY="optimized"
elif [ "$LIBRARY" == "" ]; then
    LIBRARY="debug"
elif [ "$LIBRARY" == "debug" ]; then
    LIBRARY="debug"
else
    echo "Invalid opt set, use <debug|optimized>"
    exit 1
fi

if [ ! "$3" ];then
    BUILDTAG="base"
else
    BUILDTAG=$3
fi


COMPILER=$1
PWD=$(pwd)
MPICH2DIR=${PWD}/ssg_sfi-mpich
INSTALL_DIR=/home/cjarcher/code/install/${COMPILER}/netmod-${LIBRARY}-${BUILDTAG}
THREAD_LEVEL=default
export STAGEDIR=${PWD}/stage/${COMPILER}/netmod-${LIBRARY}-${BUILDTAG}
#export STAGEDIR=/work/cjarcher/stage/${COMPILER}/netmod-${LIBRARY}-${BUILDTAG}
export OFIDIR=/home/cjarcher/code/install/${COMPILER}/ofi-${LIBRARY}-${BUILDTAG}
export MXMDIR=/home/cjarcher/code/install/${COMPILER}/mxm
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
        . ${HOME}/intel_compilervars.sh intel64
        . ${HOME}/code/setup_intel.sh
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
OPTFLAGS_COMMON="-Wall -ggdb -O3 ${MCMODEL} -DNDEBUG ${EXTRA_OPT}"
OPTLDFLAGS_COMMON="-O3 ${MCMODEL} ${EXTRA_LD_OPT}"
DEBUGFLAGS_COMMON="-Wall -ggdb ${MCMODEL} -O0 ${EXTRA_DEBUG}"
DEBUGLDFLAGS_COMMON="-O0 ${MCMODEL} ${EXTRA_LD_DEBUG}"

case ${LIBRARY} in
    optimized)
        export MPICHLIB_CFLAGS=${OPTFLAGS_COMMON}
        export MPICHLIB_CXXFLAGS=${OPTFLAGS_COMMON}
        export MPICHLIB_FCFLAGS=${OPTFLAGS_COMMON}
        export MPICHLIB_FFLAGS=${OPTFLAGS_COMMON}
        export MPICHLIB_F77FLAGS=${OPTFLAGS_COMMON}
        export MPICHLIB_LDFLAGS=${OPTLDFLAGS_COMMON}
        ;;
    debug)
        export MPICHLIB_CFLAGS=${DEBUGFLAGS_COMMON}
        export MPICHLIB_CXXFLAGS=${DEBUGFLAGS_COMMON}
        export MPICHLIB_FCFLAGS=${DEBUGFLAGS_COMMON}
        export MPICHLIB_FFLAGS=${DEBUGFLAGS_COMMON}
        export MPICHLIB_F77FLAGS=${DEBUGFLAGS_COMMON}
        export MPICHLIB_LDFLAGS=${DEBUGLDFLAGS_COMMON}
        ;;
    *)
        echo "${OPTION}: Unknown optimization type:  use optimized|debug"
        exit 1
        ;;
esac

export PM=hydra
#export DEVICES=ch3:nemesis:tcp,ofi,mxm
export DEVICES=ch3:nemesis:tcp,ofi

# BUILD
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}

#Cross
BUILD_HOST=i386-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu
BUILD_THREADLEVEL=multiple
BUILD_LOCKLEVEL=global
BUILD_ALLOCATION=default
export DISABLE_SHM="--enable-nemesis-dbg-nolocal --disable-nemesis-shm-collectives"
export CROSSFILE=${MPICH2DIR}/src/mpid/ch4/cross/gcc-linux-x86-8
export CROSSFILE=/home/cjarcher/code/mpich/mpich-adi/src/mpid/adi/cross/gcc-linux-x86-8

echo MPICHLIB_CFLAGS: $MPICHLIB_CFLAGS
echo MPICHLIB_CXXFLAGS: $MPICHLIB_CXXFLAGS
echo MPICHLIB_LDFLAGS: $MPICHLIB_LDFLAGS
echo DEVICES: $DEVICES
echo OFI_NETMOD_ARGS:  ${OFI_NETMOD_ARGS}
echo OFIDIR:  ${OFIDIR}
echo SHARED_MEMORY: ${SHARED_MEMORY}
echo BUILD_TYPE: $BUILD_TYPE
echo BUILD_THREADLEVEL: $BUILD_THREADLEVEL
echo BUILD_LOCKLEVEL: $BUILD_LOCKLEVEL
echo BUILD_ALLOCATION: $BUILD_ALLOCATION
echo MPICH2DIR: ${MPICH2DIR}
echo INSTALL_DIR: ${INSTALL_DIR}
echo STAGEDIR: "${STAGEDIR}"
echo PWD:  ${PWD}
echo HOSTNAME: ${HOSTNAME}
echo " ====== BUILDING MPICH2 : ${COMPILER}/${CONFIG} =======";

#                  --with-mxm=${MXMDIR}                                        \
if [ "$LIBRARY" == "optimized" ]; then
    if [ ! -f ./Makefile ] ; then                                     \
        echo " ====== BUILDING MPICH2 Optimized Library =======";     \
        MPILIBNAME="mpi"                                              \
                  MPICXXLIBNAME="mpigc4"                                        \
                  ${MPICH2DIR}/configure                                        \
                  --host=${BUILD_HOST}                                          \
                  --build=${BUILD_BUILD}                                        \
        		  --with-cross=${CROSSFILE}                                     \
                  --enable-cache                                                \
                  --disable-versioning                                          \
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
                  --enable-timer-type=linux86_cycle                             \
                  --enable-threads=${BUILD_THREADLEVEL}                         \
                  --enable-thread-cs=${BUILD_LOCKLEVEL}                         \
                  --enable-handle-allocation=${BUILD_ALLOCATION}                \
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
                  --enable-error-checking=no                                    \
                  --enable-error-messages=all                                   \
                  --enable-fast=all,O3                                          \
                  ${DISABLE_SHM}                                                \
\        ; fi
else
    if [ ! -f Makefile ] ; then                                     \
        echo " ====== BUILDING MPICH2 Debug Library =======";       \
        MPILIBNAME="mpi"                                            \
                  MPICXXLIBNAME="mpigc4"                                      \
                  MPICH2LIB_CFLAGS="${CFLAGS} -DMPIDI_TRACE"                  \
                  ${MPICH2DIR}/configure                                      \
                  --host=${BUILD_HOST}                                        \
                  --build=${BUILD_BUILD}                                      \
		          --with-cross=${CROSSFILE}                                   \
                  --enable-cache                                              \
                  --disable-versioning                                        \
                  --prefix=${INSTALL_DIR}                                     \
                  --mandir=${INSTALL_DIR}/man                                 \
                  --htmldir=${INSTALL_DIR}/www                                \
                  --enable-dependencies                                       \
                  --enable-g=all                                              \
                  --with-pm=${PM}                                             \
                  --with-device=${DEVICES}                                    \
                  --with-ofi=${OFIDIR}                                        \
                  --enable-romio=yes                                          \
                  --enable-f77=yes                                            \
                  --enable-fc=yes                                             \
                  --with-file-system=ufs+nfs                                  \
                  --enable-timer-type=linux86_cycle                           \
                  --enable-threads=${BUILD_THREADLEVEL}                       \
                  --enable-thread-cs=${BUILD_LOCKLEVEL}                       \
                  --enable-handle-allocation=${BUILD_ALLOCATION}              \
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
                  ${DISABLE_SHM}                                              \
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

[ $? -eq 0 ] || exit $?;
