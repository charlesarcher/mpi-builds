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
    echo "Invalid opt set, use <debug|optimized>"
    exit 1
fi

if [ ! "$3" ];then
    BUILDTAG="base"
else
    BUILDTAG=$3
fi


PWD=$(pwd)
PLATFORM_FILE=${PWD}/platform_files/optimized
COMPILER=$1
OMPIDIR=${PWD}/ompi
#OMPIDIR=${PWD}/openmpi-1.10.0
INSTALL_DIR=/home/cjarcher/code/install/${COMPILER}/openmpi-${LIBRARY}-${BUILDTAG}
STAGEDIR=${PWD}/stage/${COMPILER}/openmpi-${LIBRARY}-${BUILDTAG}

export AUTOCONFTOOLS=/home/cjarcher/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:${COMPILERPATH}:/bin:/usr/bin
export OFIDIR=/home/cjarcher/code/install/${COMPILER}/ofi-${LIBRARY}-${BUILDTAG}
export MXMDIR=${PWD}/../install/${COMPILER}/mxm

case $COMPILER in
    pgi )
        export AR=ar
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

export PM=hydra

#Cross
#BUILD_HOST=i386-pc-linux-gnu
#BUILD_BUILD=i686-pc-linux-gnu

#MCMODEL="-mcmodel=large -ftls-model=local-exec"
OPTFLAGS_COMMON="-Wall -ggdb -O3 ${MCMODEL} -DNDEBUG ${EXTRA_OPT}"
OPTLDFLAGS_COMMON="-O3 ${MCMODEL} ${EXTRA_LD_OPT}"
DEBUGFLAGS_COMMON="-Wall -ggdb ${MCMODEL} -O0 ${EXTRA_DEBUG}"
DEBUGLDFLAGS_COMMON="-O0 ${MCMODEL} ${EXTRA_LD_DEBUG}"

case ${LIBRARY} in
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

PSM_DIR=${PWD%/*}/install/${COMPILER}/psm/usr
# BUILD
mkdir -p ${STAGEDIR} && cd ${STAGEDIR}

#Cross
#              --with-mxm=${MXMDIR}                          \
#              --with-mxm-libdir=${MXMDIR}/lib               \


echo "----------------------------------------------------------------"
echo BUILDTAG:    $BUILDTAG
echo CC:          $CC
echo CFLAGS:      $CFLAGS
echo CXXFLAGS:    $CXXFLAGS
echo LDFLAGS:     $LDFLAGS
echo FLAVOR:      $BUILDFLAVOR
echo STAGEDIR:    $STAGEDIR
echo INSTALL_DIR: $INSTALL_DIR
echo OFIDIR:      $OFIDIR
echo "----------------------------------------------------------------"
if [ ! -f ./Makefile ] ; then                               \
    echo " ====== BUILDING OMPI Optimized Library ======="; \
    ${OMPIDIR}/configure                                    \
              --prefix=${INSTALL_DIR}                       \
              --with-platform=${PLATFORM_FILE}              \
              --with-libfabric=${OFIDIR}                    \
              --with-libfabric-libdir=${OFIDIR}/lib         \
              --with-mxm=no                                 \
              --with-verbs=no                               \
              --with-portals4=no                            \
              --with-psm=no                                 \
              --with-psm2=no                                \
              --with-scif=no                                \
              --with-usnic=no                               \
              --with-tm=no                                  \
              --with-munge=no                               \
              --with-slurm=no                               \
              --with-devel-headers=yes                      \
              --enable-mca-static=ofi                       \
              --with-valgrind=no
fi && make V=0 -j32 && make install


#              --with-psm2=${PSM_DIR}                        \
#              --with-psm2-libdir=${PSM_DIR}/lib             \
