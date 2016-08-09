#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi> <optimized|debug> <buildtag>"
    exit
fi

if [ ! "$2" ];then
    BUILDTYPE="debug"
else
    BUILDTYPE=$2
fi

if [ ! "$3" ];then
    BUILDTAG="base"
else
    BUILDTAG=$3
fi


COMPILER=$1
PWD=$(pwd)
OFIDIR=${PWD}/ssg_ofi-libfabric
export AUTOCONFTOOLS=${HOME}/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:/bin:/usr/bin

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
OPTFLAGS_COMMON="${WALLC} -ggdb -O3 ${MCMODEL} -DNDEBUG ${EXTRA_OPT}"
OPTLDFLAGS_COMMON="-O3 ${MCMODEL} ${EXTRA_LD_OPT}"
DEBUGFLAGS_COMMON="${WALLC} -ggdb ${MCMODEL} -O0 ${EXTRA_DEBUG}"
DEBUGLDFLAGS_COMMON="-O0 ${MCMODEL} ${EXTRA_LD_DEBUG}"

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

#export LDFLAGS=${DEBUGLDFLAGS_COMMON}
# --enable-direct=portals                                   \
# --enable-portals-address-format=[FI_ADDR | FI_ADDR_INDEX] \
# --enable-portals-flow-control=yes                         \

BUILDFLAVOR=sockets
#BUILDFLAVOR=psm2
#BUILDFLAVOR=psm

BUILD_HOST=i386-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu

STAGEDIR=$(pwd)/stage/${COMPILER}/ofi-${BUILDTYPE}-${BUILDTAG}
INSTALL_DIR=${PWD%/*}/install/${COMPILER}/ofi-${BUILDTYPE}-${BUILDTAG}
PSM_DIR=${PWD%/*}/install/${COMPILER}/psm/usr

echo "----------------------------------------------------------------"
echo BUILDTYPE:   $BUILDTYPE
echo BUILDTAG:    $BUILDTAG
echo CC:          $CC
echo CFLAGS:      $CFLAGS
echo CXXFLAGS:    $CXXFLAGS
echo LDFLAGS:     $LDFLAGS
echo FLAVOR:      $BUILDFLAVOR
echo STAGEDIR:    $STAGEDIR
echo INSTALL_DIR: $INSTALL_DIR
echo "----------------------------------------------------------------"

# BUILD
case ${BUILDFLAVOR} in
    portals)
        export PORTALS=${INSTALL_DIR}
        mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
        if [ ! -f ./Makefile ] ; then                                     \
            ${OFIDIR}/configure                                           \
            --prefix=${INSTALL_DIR}                                       \
            --mandir=${INSTALL_DIR}/man                                   \
            --with-valgrind=no                                            \
            --enable-psm=no                                               \
            --enable-psm2=no                                              \
            --enable-psm2d=no                                             \
            --enable-udp=no                                               \
            --enable-mxm=no                                               \
            --enable-verbs=no                                             \
            --enable-sockets=no                                           \
            --enable-rxm=no                                               \
            --with-portals=${PORTALS}                                     \
            --with-portals-lib=${PORTALS}/lib                             \
            ; fi
        ;;
    sockets)
        mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
        if [ ! -f ./Makefile ] ; then                                     \
            ${OFIDIR}/configure                                           \
            --prefix=${INSTALL_DIR}                                       \
            --mandir=${INSTALL_DIR}/man                                   \
            --host=${BUILD_HOST}                                          \
            --build=${BUILD_BUILD}                                        \
            --with-valgrind=no                                            \
            --enable-usnic=no                                             \
            --enable-psm=no                                               \
            --enable-psm2=no                                              \
            --enable-psm2d=no                                             \
            --enable-udp=no                                               \
            --enable-mxm=no                                               \
            --enable-verbs=no                                             \
            --enable-sockets=yes                                          \
            --enable-rxm=no                                               \
            ; fi
        ;;
    psm)
        mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
        if [ ! -f ./Makefile ] ; then                                     \
            ${OFIDIR}/configure                                           \
            --prefix=${INSTALL_DIR}                                       \
            --mandir=${INSTALL_DIR}/man                                   \
            --host=${BUILD_HOST}                                          \
            --build=${BUILD_BUILD}                                        \
            --with-valgrind=no                                            \
            --enable-usnic=no                                             \
            --enable-psm=yes                                              \
            --enable-psm2=no                                              \
            --enable-psm2d=no                                             \
            --enable-udp=no                                               \
            --enable-mxm=no                                               \
            --enable-verbs=no                                             \
            --enable-sockets=no                                           \
            --enable-rxm=no                                               \
            ; fi
        ;;
    psm2)
        mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
        if [ ! -f ./Makefile ] ; then                                     \
            ${OFIDIR}/configure                                           \
            --prefix=${INSTALL_DIR}                                       \
            --mandir=${INSTALL_DIR}/man                                   \
            --host=${BUILD_HOST}                                          \
            --build=${BUILD_BUILD}                                        \
            --with-valgrind=no                                            \
            --enable-usnic=no                                             \
            --enable-psm2=${PSM_DIR}                                      \
            --enable-psm2d=no                                             \
            --enable-udp=no                                               \
            --enable-psm=no                                               \
            --enable-truescale=no                                         \
            --enable-mxm=no                                               \
            --enable-verbs=no                                             \
            --enable-sockets=no                                           \
            --enable-rxm=no                                               \
            ; fi
        ;;
    truescale)
        mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
        if [ ! -f ./Makefile ] ; then                                     \
            ${OFIDIR}/configure                                           \
            --prefix=${INSTALL_DIR}                                       \
            --mandir=${INSTALL_DIR}/man                                   \
            --host=${BUILD_HOST}                                          \
            --build=${BUILD_BUILD}                                        \
            --with-valgrind=no                                            \
            --enable-usnic=no                                             \
            --enable-truescale=yes                                        \
            --enable-mxm=no                                               \
            --enable-verbs=no                                             \
            --enable-sockets=yes                                          \
            ; fi
        ;;
esac


make V=0 -j8 && make V=0 -j8 install
#        && rm ${INSTALL_DIR}/lib/libfabric.la
[ $? -eq 0 ] || exit $?;
