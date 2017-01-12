#!/bin/sh

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi>"
    exit
fi

HOME=/home-nfs/cjarcher/
HOME=/home/cjarcher/
COMPILER=$1
MPICH2DIR=$(pwd)/mpich-adi
THREAD_LEVEL=default
export AUTOCONFTOOLS=${HOME}/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:${COMPILERPATH}:/bin:/usr/bin

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
        if [ -e /opt/rh/devtoolset-4/enable ]; then
            . /opt/rh/devtoolset-4/enable
        fi
        . ${HOME}/intel_compilervars.sh intel64
        . ${HOME}/code/setup_intel.sh
        export LDFLAGS="${LDFLAGS} -Wl,-z,muldefs -Wl,-z,now"
        ;;
    gnu )
          if [ -e /opt/rh/devtoolset-4/enable ]; then
            . /opt/rh/devtoolset-4/enable
        fi
        . ${HOME}/code/setup_gnu.sh
        export LDFLAGS="${LDFLAGS} -Wl,-z,muldefs -Wl,-z,now"
        EXTRA_OPT="${EXTRA_OPT}"
        EXTRA_DEBUG="${EXTRA_DEBUG}"
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
BUILD_HOST=i686-pc-linux-gnu
BUILD_BUILD=i386-pc-linux-gnu

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
    LIBRARY="debug-ofi-tpo-noinline-ep-dynamic-dynamic-dynamic"
else
    LIBRARY=$2
fi

OPTFLAGS_COMMON="-ggdb -O3 -DNVALGRIND -DNDEBUG ${EXTRA_OPT}"
OPTLDFLAGS_COMMON="-O3  ${EXTRA_LD_OPT}"
DEBUGFLAGS_COMMON="-ggdb  -O0 ${EXTRA_DEBUG}"
DEBUGLDFLAGS_COMMON="-O0  ${EXTRA_LD_DEBUG}"

IFS_SAVE=${IFS}
IFS="-"
CONFIG="${LIBRARY}"
COUNT=0
for OPTION in $CONFIG; do
    case ${COUNT} in
        0)
            case ${OPTION} in
                optimized)
                    export MPICHLIB_CFLAGS="${OPTFLAGS_COMMON} ${WALLC}"
                    export MPICHLIB_CXXFLAGS="${OPTFLAGS_COMMON}  ${WALLC}"
                    export MPICHLIB_FCFLAGS="${OPTFLAGS_COMMON} ${WALLF}"
                    export MPICHLIB_FFLAGS="${OPTFLAGS_COMMON} ${WALLF}"
                    export MPICHLIB_F77FLAGS="${OPTFLAGS_COMMON} ${WALLF}"
                    export MPICHLIB_LDFLAGS=${OPTLDFLAGS_COMMON}
                    export BUILD_TYPE=optimized
                    ;;
                debug)
                    export MPICHLIB_CFLAGS="${DEBUGFLAGS_COMMON} ${WALLC}"
                    export MPICHLIB_CXXFLAGS="${DEBUGFLAGS_COMMON} ${WALLC}"
                    export MPICHLIB_FCFLAGS="${DEBUGFLAGS_COMMON} ${WALLF}"
                    export MPICHLIB_FFLAGS="${DEBUGFLAGS_COMMON} ${WALLF}"
                    export MPICHLIB_F77FLAGS="${DEBUGFLAGS_COMMON} ${WALLF}"
                    export MPICHLIB_LDFLAGS=${DEBUGLDFLAGS_COMMON}
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
                    export VISIBILITY=--disable-visibility
                ;;
                direct)
                    export VISIBILITY=--enable-visibility
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

if [ ${COUNT} -lt 8 ]; then
   echo "Error in $0 - Invalid Build Spec"
   echo "Syntax: $0 <gnu|intel|pgi> <optimization>-<adi-type>-<thread model>-<inline>-<scalable>-<direct>"
   exit
fi


# BUILD
PWD=$(pwd)
STAGEDIR=${PWD}/stage/${COMPILER}/${CONFIG}
INSTALL_DIR=${PWD%/*}/install/${COMPILER}/${CONFIG}

export LIBFABRICDIR=${PWD%/*}/install/${COMPILER}/ofi-${BUILD_TYPE}-base
export DEVICES="$DEVICES:av_table"
export CROSSFILE=${MPICH2DIR}/src/mpid/adi/cross/gcc-linux-x86-8

export LDFLAGS="${LDFLAGS} -rdynamic"

echo Running Config:  ${CONFIG}
printf "|%-30s|%-50s|\n" "------------------------------" "-------------------------------------------------"
printf "|%-30s|%-50s|\n" "Option"             "Value"
printf "|%-30s|%-50s|\n" "------------------------------" "-------------------------------------------------"
printf "|%-30s|%-50s|\n" "CC:"                    $(which ${CC})
printf "|%-30s|%-50s|\n" "CXX:"                   $(which ${CXX})
printf "|%-30s|%-50s|\n" "F77:"                   $(which ${F77})
printf "|%-30s|%-50s|\n" "FC:"                    $(which ${FC})
printf "|%-30s|%-50s|\n" "LD:"                    $(which ${LD})
printf "|%-30s|%-50s|\n" "CFLAGS:"                "${CFLAGS}"
printf "|%-30s|%-50s|\n" "CXXFLAGS:"              "${CXXFLAGS}"
printf "|%-30s|%-50s|\n" "LDFLAGS:"               "${LDFLAGS}"
printf "|%-30s|%-50s|\n" "MPICHLIB_CFLAGS:"       "${MPICHLIB_CFLAGS}"
printf "|%-30s|%-50s|\n" "MPICHLIB_CXXFLAGS:"     "${MPICHLIB_CXXFLAGS}"
printf "|%-30s|%-50s|\n" "MPICHLIB_LDFLAGS:"      "${MPICHLIB_LDFLAGS}"
printf "|%-30s|%-50s|\n" "DEVICES:"               "${DEVICES}"
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
echo   " ====== BUILDING MPICH2 : ${COMPILER} ${CONFIG} =======";

mkdir -p ${STAGEDIR} && cd ${STAGEDIR}
case ${BUILD_TYPE} in
    optimized)
    if [ ! -f ./Makefile ] ; then                                     \
        MPILIBNAME="mpi"                                              \
        MPICXXLIBNAME="mpigc4"                                        \
        ${MPICH2DIR}/configure                                        \
        --host=${BUILD_HOST}                                          \
        --build=${BUILD_BUILD}                                        \
        --with-cross=${CROSSFILE}                                     \
        --enable-cache                                                \
        --disable-versioning                                          \
        ${VISIBILITY}                                                 \
        --prefix=${INSTALL_DIR}                                       \
        --mandir=${INSTALL_DIR}/man                                   \
        --htmldir=${INSTALL_DIR}/www                                  \
        --enable-dependency-tracking                                  \
        --enable-g=none                                               \
        --with-pm=${PM}                                               \
        --with-device=${DEVICES}                                      \
        --with-fabric=${LIBFABRICDIR}                                 \
        --enable-romio=yes                                            \
        --enable-fortran=all                                          \
        --with-fwrapname=mpigf                                        \
        --with-file-system=ufs+nfs                                    \
        --enable-timer-type=linux86_cycle                             \
        --enable-threads=${BUILD_THREADLEVEL}                         \
        --enable-thread-cs=${BUILD_LOCKLEVEL}                         \
        --enable-handle-allocation=${BUILD_ALLOCATION}                \
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
        ; fi
    ;;
    debug)
        if [ ! -f Makefile ] ; then                                 \
        MPILIBNAME="mpi"                                            \
        MPICXXLIBNAME="mpigc4"                                      \
        ${MPICH2DIR}/configure                                      \
        --host=${BUILD_HOST}                                        \
        --build=${BUILD_BUILD}                                      \
        --with-cross=${CROSSFILE}                                   \
        --enable-cache                                              \
        --disable-versioning                                        \
        ${VISIBILITY}                                               \
        --prefix=${INSTALL_DIR}                                     \
        --mandir=${INSTALL_DIR}/man                                 \
        --htmldir=${INSTALL_DIR}/www                                \
        --enable-dependency-tracking                                \
        --enable-g=all                                              \
        --with-pm=${PM}                                             \
        --with-device=${DEVICES}                                    \
        --with-fabric=${LIBFABRICDIR}                               \
        --enable-romio=yes                                          \
        --enable-fortran=all                                        \
        --with-fwrapname=mpigf                                      \
        --with-file-system=ufs+nfs                                  \
        --enable-timer-type=linux86_cycle                           \
        --enable-threads=${BUILD_THREADLEVEL}                       \
        --enable-thread-cs=${BUILD_LOCKLEVEL}                       \
        --enable-handle-allocation=${BUILD_ALLOCATION}              \
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
make V=0 -j32 &&                                  \
echo "Fortran Fixup" &&                           \
cd ${STAGEDIR} && ${CC} ${CFLAGS} ${LDFLAGS}      \
    -shared src/binding/fortran/use_mpi/.libs/*.o \
            src/binding/fortran/mpif_h/.libs/*.o  \
    -o      lib/.libs/libmpigf.so &&              \
echo "Fortran Fixup Done" &&                      \
    make V=0 install -j32 && \
    rm -f ${INSTALL_DIR}/lib/*.la

[ $? -eq 0 ] || exit $?;
