#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi>"
    exit
fi

#MPICH2DIR=$(pwd)/ssg_sfi-libfabric
HOME=/home-nfs/cjarcher/
HOME=/home/cjarcher/
COMPILER=$1
MPICH2DIR=$(pwd)/ssg_sfi-mpich
THREAD_LEVEL=default
export AUTOCONFTOOLS=${HOME}/tools/x86/bin
export PATH=/bin:/usr/bin
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
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
#        . /opt/intel/composer_xe_2013_sp1.2.144/bin/compilervars.sh intel64
        export AR=xiar
        export LD=ld
        export CC=icc
        export CXX=icpc
        export F77=ifort
        export FC=ifort
        EXTRA_OPT="-ipo"
        EXTRA_OPT="${EXTRA_OPT} -no-inline-factor"
        EXTRA_OPT="${EXTRA_OPT} -inline-forceinline"
        EXTRA_OPT="${EXTRA_OPT} -inline-max-size=10000"
        EXTRA_OPT="${EXTRA_OPT} -inline-min-size=10000"
        EXTRA_OPT="${EXTRA_OPT} -inline-max-total-size=200000"
        EXTRA_OPT="${EXTRA_OPT} -inline-max-per-routine=200000"
        EXTRA_OPT="${EXTRA_OPT} -inline-max-per-compile=200000"
        export EXTRA_OPT
        ;;
    gnu )
        if [ -e /opt/rh/devtoolset-3/enable ]; then
            . /opt/rh/devtoolset-3/enable
        fi
        export LD="gcc"
        export CC="gcc"
        export CXX="g++"
        export F77="gfortran"
        export FC="gfortran"
#	EXTRA_OPT="-fprofile-use=/home/cjarcher/profile/0/home/cjarcher/code/mpich/stage/gnu/optimized-ofi-tpo-inline-ep-dynamic-ctree-ctspmpich"
	EXTRA_OPT="${EXTRA_OPT} -finline-limit=268435456"
#	EXTRA_LDOPT="-fprofile-use=/home/cjarcher/profile/0/home/cjarcher/code/mpich/stage/gnu/optimized-ofi-tpo-inline-ep-dynamic-ctree-ctspmpich"
        export EXTRA_OPT
	export EXTRA_LDOPT
        ;;
    clang )
#        export LD=ld-gold
        export LD=ld
        export CC="clang"
        export CXX="clang++"
        export F77=gfortran
        export FC=gfortran
#        export EXTRA_OPT="-flto"
        ;;
    * )
        echo "Unknown compiler type"
        exit
esac

export PM=hydra

#Cross
BUILD_HOST=i386-pc-linux-gnu
BUILD_BUILD=i686-pc-linux-gnu

# <optimization>-<adi-type>-<thread model>-<inline>-<scalable>-<direct>
# example:  debug-ofi-ts-noinline-ep-dynamic = optimized, ofi, noinline, thread per object, regular endpoints, dynamic provider
# optimization:                 optimized|debug
# adi-type:                     stub|ofi
# thread model:                 ts|tg|tpo
# adi-inliner:                  inline|noinline
# scalable ep:                  sep|ep
# direct provider:              direct|dynamic
# collectives inline:           dynamic|ctree|cstub|cdefault
# collectives transport inline: dynamic|ctspmpich
if [ ! "$2" ];then
    LIBRARY="debug-ofi-tpo-noinline-sep-dynamic-dynamic-dynamic"
else
    LIBRARY=$2
fi

OPTFLAGS_COMMON="-gdwarf-2 -O3 -DNDEBUG -fomit-frame-pointer -finline-functions -fno-strict-aliasing ${EXTRA_OPT}"
DEBUGFLAGS_COMMON="-gdwarf-2 -O0"

IFS_SAVE=${IFS}
IFS="-"
CONFIG="${LIBRARY}"
COUNT=0
for OPTION in $CONFIG; do
    case ${COUNT} in
        0)
            case ${OPTION} in
                optimized)
                    export CFLAGS=${OPTFLAGS_COMMON}
                    export CXXFLAGS=${OPTFLAGS_COMMON}
                    export FCFLAGS=${OPTFLAGS_COMMON}
                    export F77FLAGS=${OPTFLAGS_COMMON}
                    export BUILD_TYPE=optimized
                    ;;
                debug)
                    export CFLAGS=${DEBUGFLAGS_COMMON}
                    export CXXFLAGS=${DEBUGFLAGS_COMMON}
                    export FCFLAGS=${DEBUGFLAGS_COMMON}
                    export F77FLAGS=${DEBUGFLAGS_COMMON}
                    export BUILD_TYPE=debug
                ;;
                *)
                    echo "${OPTION}: Unknown optimization type:  use optimized|debug"
                    exit 1
                    ;;
            esac
            ;;
        1)
            case ${OPTION} in
                stub)
		    export FIRSTDEVICE=stub
                    export DEVICES=adi
                     ;;
                ofi)
		    export FIRSTDEVICE=ofi
                    export DEVICES=adi
                    ;;
                *)
                    echo "${OPTION}: Unknown adi type:  use stub|ofi"
                    exit 1
                    ;;
            esac
            ;;
        2)
            case ${OPTION} in
                ts)
                    export BUILD_THREADLEVEL=single
                    export BUILD_LOCKLEVEL=lock-free
                    export BUILD_ALLOCATION=default
                ;;
                tg)
                    export BUILD_THREADLEVEL=multiple
                    export BUILD_LOCKLEVEL=global
                    export BUILD_ALLOCATION=default
                ;;
                tpo)
                    export BUILD_THREADLEVEL=multiple
                    export BUILD_LOCKLEVEL=per-object
                    export BUILD_ALLOCATION=tls
                ;;
                *)
                    echo "${OPTION}: Unknown thread type:  ts|tg|tpo"
                    exit 1
                    ;;
            esac
            ;;
        3)
            case ${OPTION} in
                inline)
                    export DEVICES="${DEVICES}:inline-${FIRSTDEVICE}"
                ;;
                noinline)
                ;;
                *)
                    echo "${OPTION}: Unknown inline type:  use inline|noinline"
                    exit 1
                    ;;
            esac
            ;;
        4)
            case ${OPTION} in
                sep)
                    export DEVICES="${DEVICES}:scalable-endpoints"
                ;;
                ep)
                ;;
                *)
                    echo "${OPTION}: Unknown endpoint type:  use sp|ep"
                    exit 1
                    ;;
            esac
            ;;
        5)
            case ${OPTION} in
                dynamic)
                ;;
                direct)
                    export DEVICES="${DEVICES}:direct-provider"
                ;;
                *)
                    echo "${OPTION}: Unknown provider type:  use direct|dynamic"
                    exit 1
                    ;;
            esac
            ;;
        6)
            case ${OPTION} in
                dynamic)
                ;;
                ctree)
                    export DEVICES="${DEVICES}:inline-colltree"
                    ;;
                cstub)
                    export DEVICES="${DEVICES}:inline-collstub"
                    ;;
                cdefault)
                    export DEVICES="${DEVICES}:inline-colldefault"
                    ;;
                *)
                    echo "${OPTION}: Unknown collective inline type:  use dynamic|ctree|cstub|cdefault"
                    exit 1
                    ;;
            esac
            ;;
        7)
            case ${OPTION} in
                dynamic)
                ;;
                ctspmpich)
                    export DEVICES="${DEVICES}:inline-tspmpich"
                ;;
                *)
                    echo "${OPTION}: Unknown provider type:  use dynamic|ctspmpich"
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Fatal error, build"
            exit 1
            ;;
    esac
    COUNT=$((COUNT+1))
done
IFS=${IFS_SAVE}

# BUILD
STAGEDIR=$(pwd)/stage/${COMPILER}/${CONFIG}
INSTALL_DIR=$(pwd)/../install/${COMPILER}/${CONFIG}
export OFIDIR=$(pwd)/../install/${COMPILER}/ofi

mkdir -p ${STAGEDIR} && cd ${STAGEDIR}

export LDFLAGS="$LDFLAGS $EXTRA_LDOPT"

echo CFLAGS: $CFLAGS
echo CXXFLAGS: $CXXFLAGS
echo LDFLAGS: $LDFLAGS
echo DEVICES: $DEVICES
echo BUILD_TYPE: $BUILD_TYPE
echo BUILD_THREADLEVEL: $BUILD_THREADLEVEL
echo BUILD_LOCKLEVEL: $BUILD_LOCKLEVEL
echo BUILD_ALLOCATION: $BUILD_ALLOCATION
echo " ====== BUILDING MPICH2 : ${COMPILER}/${CONFIG} =======";
sleep 1

export CROSSFILE=${MPICH2DIR}/src/mpid/adi/cross/gcc-linux-x86-8
case ${BUILD_TYPE} in
    optimized)
    if [ ! -f ./Makefile ] ; then                                     \
        MPILIBNAME="mpi"                                              \
        MPICXXLIBNAME="mpigc4"                                        \
        ${MPICH2DIR}/configure                                        \
        --prefix=${INSTALL_DIR}                                       \
        --mandir=${INSTALL_DIR}/man                                   \
        --htmldir=${INSTALL_DIR}/www                                  \
        --enable-dependency-tracking                                  \
        --enable-g=none                                               \
        --with-pm=${PM}                                               \
        --with-device=${DEVICES}                                      \
        --with-fabric=${OFIDIR}                                       \
        --enable-romio=yes                                            \
        --enable-fc=yes                                               \
        --enable-f77=yes                                              \
        --with-file-system=ufs+nfs                                    \
        --enable-timer-type=mach_absolute_time                        \
        --enable-threads=${BUILD_THREADLEVEL}                         \
        --enable-thread-cs=${BUILD_LOCKLEVEL}                         \
        --enable-handle-allocation=${BUILD_ALLOCATION}                \
        --with-smpcoll=yes                                            \
        --enable-timing=none                                          \
        --with-assert-level=0                                         \
        --enable-shared=yes                                           \
        --enable-sharedlibs=osx-gcc                                   \
        --enable-static=yes                                           \
        --disable-debuginfo                                           \
        --enable-error-checking=no                                    \
        --enable-error-messages=all                                   \
        --enable-fast=all,O3                                          \
        ; fi
    ;;
    debug)
        if [ ! -f Makefile ] ; then                                 \
        ${MPICH2DIR}/configure                                      \
        --prefix=${INSTALL_DIR}                                     \
        --mandir=${INSTALL_DIR}/man                                 \
        --htmldir=${INSTALL_DIR}/www                                \
        --enable-g=all                                              \
        --with-pm=${PM}                                             \
        --with-device=${DEVICES}                                    \
        --with-fabric=${OFIDIR}                                     \
        --enable-romio=yes                                          \
        --enable-fc=yes                                             \
        --enable-f77=yes                                            \
        --enable-timer-type=mach_absolute_time                      \
        --with-file-system=ufs+nfs                                  \
        --enable-threads=${BUILD_THREADLEVEL}                       \
        --enable-thread-cs=${BUILD_LOCKLEVEL}                       \
        --enable-handle-allocation=${BUILD_ALLOCATION}              \
        --with-smpcoll=yes                                          \
        --enable-shared=yes                                         \
        --enable-sharedlibs=osx-gcc                                 \
        --enable-static=yes                                         \
        --enable-error-checking=all                                 \
        --enable-error-messages=all                                 \
        --enable-fast=none                                          \
        ; fi
    ;;
    *)
        echo " ======= ERROR, Invalid build type ============="
        exit 1;
esac

#find ./ -maxdepth 2 -name Makefile -exec patch --input=../mpatch {} \;
#find ./ -maxdepth 3 -name Makefile  -exec patch --input=../mpatch {} \;
#scan-build -V make V=0 -j32
#exit
make V=0 -j4 && make V=0 install -j4

#     &&                                  \
#echo "Fortran Fixup" &&                           \
#cd ${STAGEDIR} && ${CC} ${CFLAGS} ${LDFLAGS}      \
#    -shared src/binding/fortran/use_mpi/.libs/*.o \
#            src/binding/fortran/mpif_h/.libs/*.o  \
#    -o      lib/.libs/libmpigf.so &&              \
#echo "Fortran Fixup Done" &&                      \

[ $? -eq 0 ] || exit $?;
