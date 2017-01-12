#!/bin/sh

BUILDSPEC="\
# <optimization>-<ch4-type>-<thread model>-<inline>-<scalable>-<direct>-<mpi_link>-<av>-<shared memory>-<build_tag>
# example:  debug-ofi-tpo-noinline-ep-direct-external-map-disabled = optimized, ofi, noinline,
#            thread per object, basic endpoints, direct provider, external ofi libraries, AV map, disabled shared memory
# optimization:                  optimized|debug
# ch4-type:                      stubnm|ofi|ch3
# ch4/ch3 thread model:          ts|tg|tpo
# ch4 inliner:                   inline|noinline
# ch4 libfabric scalable ep:     sep|ep
# ch4 libfabric direct provider: direct|indirect
# ch4/ch3 MPI link style:        embedded|external
# ch4 libfabric AV method        table|map
# ch4|ch3 shared memory type     disabled|enabled|exclusive
# ch4 libfabric send method      tagged|am
# build tag                      tag of this build ("base" is default)
"

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel|pgi> <build-spec>"
    echo "${BUILDSPEC}"
    exit
fi

PWD=$(pwd)
HOME=/home/cjarcher/
COMPILER=$1
MPICH2DIR=${PWD}/ssg_sfi-mpich
THREAD_LEVEL=default
export AUTOCONFTOOLS=${HOME}/tools/x86/bin
export PATH=${AUTOCONFTOOLS}:/bin:/usr/bin:.
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

if [ ! "$2" ];then
    LIBRARY="debug-ofi-tpo-noinline-ep-indirect-embedded-map-enabled-tagged-base"
else
    LIBRARY=$2
fi

OPTFLAGS_COMMON="-ggdb -O3 -DNVALGRIND -DNDEBUG ${EXTRA_OPT}"
OPTLDFLAGS_COMMON="-O3  ${EXTRA_LD_OPT}"
DEBUGFLAGS_COMMON="-ggdb  -O0 ${EXTRA_DEBUG}"
DEBUGLDFLAGS_COMMON="-O0  ${EXTRA_LD_DEBUG}"

export EXTERNAL_LIBRARIES=/home/cjarcher/code/install/gnu/uuid/lib/libuuid.a

VISIBILITY="-fvisibility=hidden"
STATIC_FABRIC=0
IFS_SAVE=${IFS}
IFS="-"
CONFIG="${LIBRARY}"
COUNT=0
for OPTION in $CONFIG; do
    case ${COUNT} in
        0)
            case ${OPTION} in
                optimized)
                    export MPICHLIB_CFLAGS="${OPTFLAGS_COMMON} -std=gnu99 ${WALLC} ${VISIBILITY}"
                    export MPICHLIB_CXXFLAGS="${OPTFLAGS_COMMON}  ${WALLC}"
                    export MPICHLIB_FCFLAGS="${OPTFLAGS_COMMON} ${WALLF}"
                    export MPICHLIB_FFLAGS="${OPTFLAGS_COMMON} ${WALLF}"
                    export MPICHLIB_F77FLAGS="${OPTFLAGS_COMMON} ${WALLF}"
                    export MPICHLIB_LDFLAGS=${OPTLDFLAGS_COMMON}
                    export BUILD_TYPE=optimized
                    ;;
                debug)
                    export MPICHLIB_CFLAGS="${DEBUGFLAGS_COMMON} -std=gnu99 ${WALLC} ${VISIBILITY}"
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
                stubnm)
                    export FIRSTDEVICE=stubnm
                    export DEVICES=ch4
                    ;;
                ofi)
                    export FIRSTDEVICE=ofi
                    export DEVICES=ch4
                    ;;
                ch3)
                    export FIRSTDEVICE=ofi
                    export DEVICES=ch3:nemesis
                    ;;
                *)
                    echo "${OPTION}: Unknown ch4 type:  use stubnm|ofi"
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
                    export DEVICES="$DEVICES:${FIRSTDEVICE}"
                    ;;
                noinline)
                    if [ "${DEVICES}" = "ch3:nemesis" ]; then
                        case ${FIRSTDEVICE} in
                            tcp)
                                export DEVICES="$DEVICES:tcp,ofi"
                                ;;
                            ofi)
                                export DEVICES="$DEVICES:ofi,tcp"
                                ;;
                            *)
                                echo "${OPTION}: Bad first provider"
                                exit 1
                                ;;
                        esac
                    else
                        case ${FIRSTDEVICE} in
                            stubnm)
                                export DEVICES="$DEVICES:stubnm,ofi"
                                ;;
                            ofi)
                                export DEVICES="$DEVICES:ofi,stubnm"
                                ;;
                            *)
                                echo "${OPTION}: Bad first provider"
                                exit 1
                                ;;
                        esac
                    fi
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
                  export OFI_NETMOD_ARGS=${OFI_NETMOD_ARGS}:scalable-endpoints
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
                indirect)
                ;;
                direct)
                  export OFI_NETMOD_ARGS=${OFI_NETMOD_ARGS}:direct-provider
                ;;
                *)
                    echo "${OPTION}: Unknown provider type:  use indirect|direct"
                    exit 1
                    ;;
            esac
            ;;
        6)
            case ${OPTION} in
                external)
                    export LIBFABRIC="external"
                ;;
                embedded)
                    export LIBFABRIC="embedded"
                ;;
                *)
                    echo "${OPTION}: Unknown provider link type:  use external|embedded"
                    exit 1
                    ;;
            esac
            ;;
        7)
            case ${OPTION} in
                map)
                ;;
                table)
                  export OFI_NETMOD_ARGS=${OFI_NETMOD_ARGS}:av-table
                ;;
                *)
                    echo "${OPTION}: Unknown AV type:  use map|table"
                    exit 1
                    ;;
            esac
            ;;
        8)
            case ${OPTION} in
                disabled)
                    SHARED_MEMORY=no
                    if [ "${DEVICES}" = "ch3:nemesis" ]; then
                        export DISABLE_CH3_SHM="--enable-nemesis-dbg-nolocal --disable-nemesis-shm-collectives"
                    fi
                ;;
                enabled)
                    SHARED_MEMORY=yes:posix
                    #SHARED_MEMORY=yes
                ;;
                exclusive)
                    SHARED_MEMORY=exclusive:posix
                    #SHARED_MEMORY=exclusive:shmam
                    #SHARED_MEMORY=exclusive
                    ;;
                *)
                    echo "${OPTION}: Unknown SHARED MEMORY type:  use no|yes|exclusive"
                    exit 1
                    ;;
            esac
            ;;
        9)
            case ${OPTION} in
                tagged)
                ;;
                am)
                  export OFI_NETMOD_ARGS=${OFI_NETMOD_ARGS}:no-tagged
                ;;
                *)
                    echo "${OPTION}: Unknown Tagged Format:  use tagged|am"
                    exit 1
                    ;;
            esac
            ;;
        10)
            export BUILD_TAG=${OPTION}
            ;;
        *)
            echo "Fatal error, build"
            exit 1
            ;;
    esac
    COUNT=$((COUNT+1))
done
IFS=${IFS_SAVE}

if [ ${COUNT} -lt 11 ]; then
   echo "Error in $0 - Invalid Build Spec"
   echo "Syntax: $0 <gnu|intel|pgi> <optimization>-<ch4-type>-<thread model>-<inline>-<scalable>-<direct>-<link>-<av>-<shared>-<tagged>-<buildtag>"
   echo "${BUILDSPEC}"
   exit
fi

# BUILD
PSM_DIR=/home/cjarcher/code/install/${COMPILER}/psm/usr
#STAGEDIR=${PWD}/stage/${COMPILER}/${CONFIG}
STAGEDIR=/work/cjarcher/stage/${COMPILER}/${CONFIG}
#export TMP=${STAGEDIR}/tmp

case ${LIBFABRIC} in
    external)
        export LIBFABRICDIR=/home/cjarcher/code/install/${COMPILER}/ofi-${BUILD_TYPE}-${BUILD_TAG}
        export USE_LIBFABRIC="--with-libfabric=${LIBFABRICDIR}"
    ;;
    embedded)
        export USE_LIBFABRIC="--enable-usnic=no     \
                              --enable-psm=no       \
                              --enable-mxm=no       \
                              --enable-rxm=no       \
                              --enable-verbs=no     \
                              --enable-sockets=no   \
                              --enable-rxm=no       \
                              --enable-rxd=no       \
                              --enable-udp=no       \
                              --enable-psm2=no      \
                              --enable-psm2d=no     \
                              --enable-truescale=no \
                              --enable-opa=yes      \
                              --enable-embedded     \
                             "
    ;;
    *)
        echo "Bad libfabric option"
        exit 1
esac

export OFI_NETMOD_ARGS=${OFI_NETMOD_ARGS}:no-data
export OFI_NETMOD_ARGS=$(echo ${OFI_NETMOD_ARGS} | sed 's/^://g')
export INSTALL_DIR=/home/cjarcher/code/install/${COMPILER}/${CONFIG}
export CROSSFILE=${MPICH2DIR}/src/mpid/ch4/cross/gcc-linux-x86-8
export SCAN_BUILD=${SCAN_BUILD}

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
echo   " ====== BUILDING MPICH2 : ${COMPILER} ${CONFIG} =======";
mkdir -p ${STAGEDIR} && cd ${STAGEDIR} ||die "Cannot cd to stagedir"
case ${BUILD_TYPE} in
    optimized)
        if [ ! -f ./Makefile ] ; then                                               \
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
                      --enable-dependency-tracking                                  \
                      --enable-g=none                                               \
                      --with-pm=${PM}                                               \
                      --with-device=${DEVICES}                                      \
                      ${USE_LIBFABRIC}                                              \
                      --enable-romio=yes                                            \
                      --enable-fortran=all                                          \
                      --with-fwrapname=mpigf                                        \
                      --with-file-system=ufs+nfs                                    \
                      --enable-timer-type=linux86_cycle                             \
                      --enable-threads=${BUILD_THREADLEVEL}                         \
                      --enable-thread-cs=${BUILD_LOCKLEVEL}                         \
                      --enable-handle-allocation=${BUILD_ALLOCATION}                \
                      --enable-ch4-shm=${SHARED_MEMORY}                             \
                      --with-ch4-netmod-ofi-args=${OFI_NETMOD_ARGS}                 \
                      --with-mpe=no                                                 \
                      --with-smpcoll=yes                                            \
                      --without-valgrind                                            \
                      --enable-timing=none                                          \
                      --with-aint-size=8                                            \
                      --with-assert-level=0                                         \
                      --enable-shared                                               \
                      --enable-static                                               \
                      --disable-debuginfo                                           \
                      --enable-error-checking=no                                    \
                      --enable-error-messages=all                                   \
                      --enable-fast=all,O3                                          \
                      ${DISABLE_CH3_SHM}                                            \
        ;fi
        ;;
    debug)
        if [ ! -f Makefile ] ; then                                               \
                      MPILIBNAME="mpi"                                            \
                      MPICXXLIBNAME="mpigc4"                                      \
                      ${SCAN_BUILD} ${MPICH2DIR}/configure                        \
                      --host=${BUILD_HOST}                                        \
                      --build=${BUILD_BUILD}                                      \
                      --with-cross=${CROSSFILE}                                   \
                      --enable-cache                                              \
                      --disable-versioning                                        \
                      --prefix=${INSTALL_DIR}                                     \
                      --mandir=${INSTALL_DIR}/man                                 \
                      --htmldir=${INSTALL_DIR}/www                                \
                      --enable-dependency-tracking                                \
                      --enable-g=all                                              \
                      --with-pm=${PM}                                             \
                      --with-device=${DEVICES}                                    \
                      ${USE_LIBFABRIC}                                            \
                      --enable-romio=yes                                          \
                      --enable-fortran=all                                        \
                      --with-fwrapname=mpigf                                      \
                      --with-file-system=ufs+nfs                                  \
                      --enable-timer-type=linux86_cycle                           \
                      --enable-threads=${BUILD_THREADLEVEL}                       \
                      --enable-thread-cs=${BUILD_LOCKLEVEL}                       \
                      --enable-handle-allocation=${BUILD_ALLOCATION}              \
                      --enable-ch4-shm=${SHARED_MEMORY}                           \
                      --with-ch4-netmod-ofi-args=${OFI_NETMOD_ARGS}               \
                      --with-mpe=no                                               \
                      --with-smpcoll=yes                                          \
                      --without-valgrind                                          \
                      --enable-timing=runtime                                     \
                      --with-aint-size=8                                          \
                      --with-assert-level=2                                       \
                      --enable-shared                                             \
                      --enable-static                                             \
                      --disable-debuginfo                                         \
                      --enable-error-checking=all                                 \
                      --enable-error-messages=all                                 \
                      --enable-fast=none                                          \
                      ${DISABLE_CH3_SHM}                                          \
        ;fi
        ;;
    *)
        echo " ======= ERROR, Invalid build type ============="
        exit 1;
esac


#find ./ -maxdepth 2 -name Makefile -exec patch --input=../mpatch {} \;
#find ./ -maxdepth 3 -name Makefile  -exec patch --input=../mpatch {} \;
#exit
make V=0 -j32 || die "Make Failed"
cd ${STAGEDIR} || die "Cannot cd to ${STAGEDIR}"

#echo "Fortran Fixup"
#${CC} ${CFLAGS} ${LDFLAGS}                          \
#      -shared src/binding/fortran/use_mpi/.libs/*.o \
#      src/binding/fortran/mpif_h/.libs/*.o          \
#      -o      lib/.libs/libmpigf.so ||              \
#    die "Fortran Fixup Failed"
#echo "Fortran Fixup Done";

echo "Embedding External Libraries lib"
(echo create libtemp.a;
 echo addlib ${STAGEDIR}/lib/.libs/libmpi.a;
 IFS_SAVE=${IFS}
 IFS=","
 for LIB in ${EXTERNAL_LIBRARIES}; do
     echo addlib ${LIB};
 done
 IFS=${IFS_SAVE}
 echo save;
 echo end;
) | ${AR} -M || die "Cannot create static lib"
cp libtemp.a ${STAGEDIR}/lib/.libs/libmpi.a      || die "Cannot replace libmpi.a"
echo "Embedding OFI lib Done"

#echo "Patchelf convenience library dependencies"
#patchelf --set-rpath "${PSM_DIR}/lib:"$(patchelf --print-rpath ${STAGEDIR}/lib/.libs/libmpi.so) ${STAGEDIR}/lib/.libs/libmpi.so

make V=0 install -j32 || die "Make Failed"
#rm -f ${INSTALL_DIR}/lib/*.la

[ $? -eq 0 ] || exit $?;

