#!/home/cjarcher/tools/x86/bin/bash

#requires bash 4.3
trap "kill 0" SIGINT

BUILDSPEC="\
# <optimization>-<ch4-type>-<thread model>-<inline>-<scalable>-<direct>-<mpi_link>-<av>-<shared memory>-<build_tag>
# example:  debug-ofi-tpo-noinline-ep-direct-external-map-disabled = optimized, ofi, noinline,
#            thread per object, basic endpoints, direct provider, external ofi libraries, AV map, disabled shared memory
# optimization:                  optimized|debug
# ch4-type:                      stub|ofi|ch3
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

#FULL BUILD SET:  LOTS OF BUILDS!!!!
OPTIMIZATIONS="optimized debug"
NETMODTYPES="ofi stub"
THREADMODELS="tpo ts tg"
NETMODINLINERS="noinline inline"
EPTYPES="ep sep"
PROVTYPES="direct indirect"
LINKTYPES="embedded external"
MAPTYPES="table map"
SHMEMTYPE="enabled disabled exclusive"
TAG_FORMATS="tagged am"
TAGS="base"

OPTIMIZATIONS="optimized debug"
NETMODTYPES="ofi"
THREADMODELS="tpo ts tg"
NETMODINLINERS="inline noinline"
EPTYPES="ep"
PROVTYPES="indirect"
LINKTYPES="embedded"
MAPTYPES="table"
SHMEMTYPE="disabled exclusive"
TAG_FORMATS="tagged am"
TAGS="base"

# ### Performance ###
OPTIMIZATIONS="optimized debug"
NETMODTYPES="ofi ch3"
THREADMODELS="ts tpo tg"
NETMODINLINERS="inline"
EPTYPES="ep"
PROVTYPES="indirect"
LINKTYPES="embedded"
MAPTYPES="map"
SHMEMTYPE="disabled exclusive"
TAG_FORMATS="tagged"
TAGS="base"

# OPTIMIZATIONS="optimized"
# NETMODTYPES="ofi"
# THREADMODELS="tpo ts"
# NETMODINLINERS="inline"
# EPTYPES="ep"
# PROVTYPES="indirect"
# LINKTYPES="embedded"
# MAPTYPES="map"
# SHMEMTYPE="disabled"
# TAG_FORMATS="tagged"
# TAGS="base"

#BUILD SUBSET
for optimization in ${OPTIMIZATIONS}; do
    for netmodtype in ${NETMODTYPES}; do
        for threadmodel in ${THREADMODELS}; do
            for netmodinliner in ${NETMODINLINERS}; do
                for eptype in ${EPTYPES}; do
                    for provtype in ${PROVTYPES}; do
                        for linktype in ${LINKTYPES}; do
                            for maptype in ${MAPTYPES}; do
                                for shmemtype in ${SHMEMTYPE}; do
                                    for tformat in ${TAG_FORMATS}; do
                                        for tag in ${TAGS}; do
                                            LIBRARIES="${LIBRARIES} ${optimization}-${netmodtype}-${threadmodel}-${netmodinliner}-${eptype}-${provtype}-${linktype}-${maptype}-${shmemtype}-${tformat}-${tag}"
                                        done
                                    done
                                done
                            done
                        done
                    done
                done
            done
        done
    done
done
LIBRARIES="${LIBRARIES}"
COMPILERS="gnu intel clang"
for LIBRARY in ${LIBRARIES}; do
    echo $LIBRARY
done
#LIBRARIES="${LIBRARIES} optimized"
#HOSTS="f018 f019 f020 f025 f026 f029 f030"
HOSTS="f055 f056 f057 f058"
#HOSTS="f029 f030"
HOSTS_ARRAY=($HOSTS)
NUM_HOSTS=${#HOSTS_ARRAY[@]}
declare -A HOST_AVAILABLE
declare -A PID_TO_HOST

echo -n "Running on hosts:  "
for HOST in "${HOSTS_ARRAY[@]}"; do
    HOST_AVAILABLE[${HOST}]=1
    echo -n "${HOST} " #=${HOST_AVAILABLE[${HOST}]}
done
echo ""

tmp1=($LIBRARIES)
tmp2=($COMPILERS)
COUNTLIB=${#tmp1[@]}
COUNTCOMPILER=${#tmp2[@]}
TOTAL=$((COUNTLIB*COUNTCOMPILER))
echo Starting build for ${COUNTLIB} Libraries "*" ${COUNTCOMPILER} compilers = ${TOTAL} total builds


rm -rf logs/*
mkdir -p logs/failed/gnu
mkdir -p logs/failed/intel
mkdir -p logs/failed/clang
mkdir -p logs/success/gnu
mkdir -p logs/success/intel
mkdir -p logs/success/clang


function getnexthost()
{
    HOST=""
    for CHECKHOST in "${HOSTS_ARRAY[@]}"; do
        if [ "${HOST_AVAILABLE[${CHECKHOST}]}" == "1" ]; then
            HOST=${CHECKHOST}
            HOST_AVAILABLE[${HOST}]=0
            break
        fi
    done
}

echo "|----------|----------|------------------------------------------------------------|----------|-----|-----|"
printf "|%-10s|%-10s|%-60s|%-10s|%-5s|%-5s|\n" "PID" "COMPILER" "BUILD" "STATUS" "WARN" "ERR"
echo "|----------|----------|------------------------------------------------------------|----------|-----|-----|"
COUNT=1
A=1
for COMPILER in ${COMPILERS}; do
    if [ "${COMPILER}" = "intel" ]; then
        WARNING="warning "
        ERROR="error "
    else
        WARNING="warning:"
        ERROR="error:"
    fi
    for LIBRARY in ${LIBRARIES}; do
        getnexthost
        if [ "${HOST}" == "" ]; then
            wait -n
            for donepid in "${!PID_TO_HOST[@]}"; do
                if  kill -0 "$donepid" 2>/dev/null; then
                    :
                else
                    wait $donepid
                    TESTHOST=${PID_TO_HOST[$donepid]}
                    unset PID_TO_HOST[$donepid]
                    HOST_AVAILABLE[${TESTHOST}]=1
                fi
            done
            getnexthost
            if [ "${HOST}" == "" ]; then
                echo "Error in hosts"
                exit 1
            fi
        fi
        A=$((A+1))
        mkdir -p ./tmp
        MYTMP=$(mktemp -d -p ./tmp)
        SH="ssh ${HOST} mkdir -p ${PWD}/${MYTMP} '&&' cd ${PWD} '&&' cp -al ssg_sfi-mpich ${MYTMP}/ssg_sfi-mpich '&&' cd ${PWD}/${MYTMP} '&&' sh"
        (
            if [ "${LIBRARY}" == "debug" ]; then
                LOGFILE=logs/${COMPILER}.netmod.${LIBRARY}.log
                cmd="${SH} ../../build-netmod.sh ${COMPILER} debug ${LIBRARY}"
                echo $cmd >> logs/replay.sh
                (eval $cmd > ${LOGFILE} 2>&1)&
                pid=$!
            elif [ "${LIBRARY}" == "optimized" ]; then
                LOGFILE=logs/${COMPILER}.netmod.${LIBRARY}.log
                cmd="${SH} ../../build-netmod.sh ${COMPILER} optimized ${LIBRARY}"
                echo $cmd >> logs/replay.sh
                (eval $cmd > ${LOGFILE}   2>&1)&
                pid=$!
            else
                LOGFILE=logs/${COMPILER}.${LIBRARY}.log
                cmd="${SH} ../../build-ch4.sh ${COMPILER} ${LIBRARY}"
                echo $cmd >> logs/replay.sh
                (eval $cmd > ${LOGFILE} 2>&1)&
                pid=$!
            fi
            wait ${pid}
            if [ $? -eq 0 ]; then
                WARN=$(grep "${WARNING}" ${LOGFILE} | grep -c ch4)
                ERR=$(grep "${ERROR}" ${LOGFILE} | grep -c ch4)
                mv ${LOGFILE} logs/success/${COMPILER}
                printf "|%-10s|%-10s|%-60s|%-10s|%-5s|%-5s|\n" $COUNT:$pid ${COMPILER} ${LIBRARY} "SUCCESS" ${WARN} ${ERR}
            else
                WARN=$(grep "${WARNING}" ${LOGFILE} | grep -c ch4)
                ERR=$(grep "${ERROR}" ${LOGFILE} | grep -c ch4)
                mv ${LOGFILE} logs/failed/${COMPILER}
                printf "|%-10s|%-10s|%-60s|%-10s|%-5s|%-5s|\n" $COUNT:$pid ${COMPILER} ${LIBRARY} "FAIL" ${WARN} ${ERR}
            fi
        ) &
        pid=$!
        PID_TO_HOST[${pid}]=${HOST}
        COUNT=$((COUNT+1))
    done
    #wait here to sync compiler builds
done

wait

echo "|----------|----------|------------------------------------------------------------|----------|-----|-----|"

