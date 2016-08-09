#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi>"
    exit
fi

LIBRARY=$2
if [ "$LIBRARY" == "optimized" ]; then
    LIBRARY="optimized"
elif [ "$LIBRARY" == "" ]; then
    LIBRARY="debug"
elif [ "$LIBRARY" == "debug" ]; then
    LIBRARY="debug"
else
    echo "Invalid opt set, use <debug|opt>"
    exit
fi

if [ ! "$3" ];then
    BUILDTAG="base"
else
    BUILDTAG=$3
fi

COMPILER=$1
PWD=$(pwd)
MPICH2DIR=${PWD}/mvapich2-2.2rc1
export INSTALL_DIR=/home/cjarcher/code/install/${COMPILER}/mvapich-${LIBRARY}-${BUILDTAG}
export STAGEDIR=${PWD}/stage/${COMPILER}/mvapich-${LIBRARY}-${BUILDTAG}
export OFIDIR=/home/cjarcher/code/install/${COMPILER}/ofi-${LIBRARY}-${BUILDTAG}
export AUTOCONFTOOLS=/home/cjarcher/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:${COMPILERPATH}:/bin:/usr/bin
THREAD_LEVEL=default

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
        if [ -e /opt/rh/devtoolset-4/enable ]; then
            . /opt/rh/devtoolset-4/enable
        fi
        . ${HOME}/code/setup_gnu.sh
        ;;
    clang )
        if [ -e /opt/rh/devtoolset-4/enable ]; then
            . /opt/rh/devtoolset-4/enable
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
export DEVICES=ch3:psm
export PSM_DIR=${PWD%/*}/install/${COMPILER}/psm/usr


# BUILD
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}

#Cross
BUILD_HOST=i386-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu
BUILD_THREADLEVEL=multiple
BUILD_LOCKLEVEL=global
BUILD_ALLOCATION=default

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
echo " ====== BUILDING MVAPICH2 : ${COMPILER} ${CONFIG} =======";
if [ "$LIBRARY" == "optimized" ]; then
    if [ ! -f ./Makefile ] ; then                                     \
        echo " ====== BUILDING MPICH2 Optimized Library =======";     \
        MPILIBNAME="mpi"                                              \
        MPICXXLIBNAME="mpigc4"                                        \
        ${MPICH2DIR}/configure                                        \
        --host=${BUILD_HOST}                                          \
        --build=${BUILD_BUILD}                                        \
        --with-cross=${MPICH2DIR}/src/mpid/pamid/cross/pe8            \
        --enable-cache                                                \
        --disable-versioning                                          \
        --prefix=${INSTALL_DIR}                                       \
        --mandir=${INSTALL_DIR}/man                                   \
        --htmldir=${INSTALL_DIR}/www                                  \
        --enable-dependencies                                         \
        --enable-g=none                                               \
        --with-device=${DEVICES}                                      \
        --with-psm2=${PSM_DIR}                                        \
        --with-psm2-include=${PSM_DIR}/include                        \
        --with-psm2-lib=${PSM_DIR}/lib                                \
        --enable-romio=yes                                            \
        --disable-fortran                                             \
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
        --build=${BUILD_BUILD}                                      \
        --with-cross=${MPICH2DIR}/src/mpid/pamid/cross/pe8          \
        --enable-cache                                              \
        --disable-versioning                                        \
        --prefix=${INSTALL_DIR}                                     \
        --mandir=${INSTALL_DIR}/man                                 \
        --htmldir=${INSTALL_DIR}/www                                \
        --enable-dependencies                                       \
        --enable-g=all                                              \
        --with-device=${DEVICES}                                    \
        --with-psm2=${PSM_DIR}                                      \
        --with-psm2-include=${PSM_DIR}/include                      \
        --with-psm2-lib=${PSM_DIR}/lib                              \
        --enable-romio=yes                                          \
        --disable-fortran                                           \
        --with-file-system=ufs+nfs                                  \
        --enable-timer-type=linux86_cycle                           \
        --enable-threads=${BUILD_THREADLEVEL}                       \
        --enable-thread-cs=${BUILD_LOCKLEVEL}                       \
        --enable-handle-allocation=${BUILD_ALLOCATION}              \
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
#echo "Fortran Fixup" &&                           \
#cd ${STAGEDIR} && ${CC} ${CFLAGS} ${LDFLAGS}      \
#    -shared src/binding/fortran/use_mpi/.libs/*.o \
#            src/binding/fortran/mpif_h/.libs/*.o  \
#    -o      lib/.libs/libmpigf.so &&              \
#echo "Fortran Fixup Done" &&                      \
make V=0 install -j32
