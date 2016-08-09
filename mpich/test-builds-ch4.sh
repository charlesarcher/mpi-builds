#!/bin/sh

trap "kill 0" SIGINT


# <optimization>-<ch4-type>-<thread model>-<inline>-<scalable>-<direct>-<mpi_link>-<av>-<shared memory>-<build_tag>
# example:  debug-ofi-tpo-noinline-ep-direct-shared-map-disabled = optimized, ofi, noinline,
#            thread per object, basic endpoints, direct provider, shared libraries, AV map, disabled shared memory
# optimization:                 optimized|debug
# ch4-type:                     stub|ofi|ch3
# ch4/ch3 thread model:         ts|tg|tpo
# ch4 inliner:                  inline|noinline
# ch4 OFI scalable ep:          sep|ep
# ch4 OFI direct provider:      direct|indirect
# ch4/ch3 MPI link style:       static|shared
# ch4 OFI AV method             table|map
# ch4|ch3 shared memory type    disabled|enabled|exclusive
# ch4 ofi send method           tagged|am
# build tag                     tag of this build ("base" is default)

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

### Sweep ###
OPTIMIZATIONS="debug optimized"
NETMODTYPES="ofi"
THREADMODELS="tpo ts"
NETMODINLINERS="inline"
EPTYPES="ep"
PROVTYPES="indirect"
LINKTYPES="embedded"
MAPTYPES="map"
SHMEMTYPE="disabled exclusive"
TAG_FORMATS="tagged"
TAGS="base"

# ### Performance ###
#OPTIMIZATIONS="debug optimized"
#NETMODTYPES="ofi ch3"
#THREADMODELS="ts tg tpo"
#NETMODINLINERS="inline"
#EPTYPES="ep"
#PROVTYPES="direct"
#LINKTYPES="embedded"
#MAPTYPES="map"
#SHMEMTYPE="disabled"
#TAG_FORMATS="tagged"
#TAGS="base"

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
                                            echo "${optimization}-${netmodtype}-${threadmodel}-${netmodinliner}-${eptype}-${provtype}-${linktype}-${maptype}-${shmemtype}-${tformat}-${tag}"
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

tmp1=($LIBRARIES)
tmp2=($COMPILERS)
COUNTLIB=${#tmp1[@]}
COUNTCOMPILER=${#tmp2[@]}
TOTAL=$((COUNTLIB*COUNTCOMPILER))
echo Starting build for ${COUNTLIB} Libraries "*" ${COUNTCOMPILER} compilers = ${TOTAL} total builds

rm -rf logs2/*
mkdir -p logs2/failed/gnu
mkdir -p logs2/failed/intel
mkdir -p logs2/failed/clang
mkdir -p logs2/success/gnu
mkdir -p logs2/success/intel
mkdir -p logs2/success/clang

echo "|----------|----------|------------------------------------------------------------|----------|-----|-----|"
printf "|%-10s|%-10s|%-60s|%-10s|%-5s|%-5s|\n" "PID" "COMPILER" "BUILD" "STATUS" "WARN" "ERR"
echo "|----------|----------|------------------------------------------------------------|----------|-----|-----|"
COUNT=1
for COMPILER in ${COMPILERS}; do
    (
        #SH="ssh f012 cd ${PWD} && sh"
        if [ "${COMPILER}" = "intel" ]; then
            WARNING="warning "
            ERROR="error "
        else
            WARNING="warning:"
            ERROR="error:"
        fi

        SH="sh"
        for LIBRARY in ${LIBRARIES}; do
            if [ "${LIBRARY}" == "debug" ]; then
                LOGFILE=logs2/${COMPILER}.netmod.${LIBRARY}.log
                (${SH} ./build-netmod.sh ${COMPILER} debug ${LIBRARY} > ${LOGFILE}   2>&1)&
            elif [ "${LIBRARY}" == "optimized" ]; then
                LOGFILE=logs2/${COMPILER}.netmod.${LIBRARY}.log
                (${SH} ./build-netmod.sh ${COMPILER} optimized ${LIBRARY} > ${LOGFILE}   2>&1)&
            else
                LOGFILE=logs2/${COMPILER}.${LIBRARY}.log
                (${SH} ./build-ch4.sh ${COMPILER} ${LIBRARY} > ${LOGFILE} 2>&1)&
            fi
            pid=$!
            wait ${pid}
            if [ $? -eq 0 ]; then
                WARN=$(grep "${WARNING}" ${LOGFILE} | grep -c ch4)
                ERR=$(grep "${ERROR}" ${LOGFILE} | grep -c ch4)
                mv ${LOGFILE} logs2/success/${COMPILER}
                printf "|%-10s|%-10s|%-60s|%-10s|%-5s|%-5s|\n" $COUNT:$pid ${COMPILER} ${LIBRARY} "SUCCESS" ${WARN} ${ERR}
            else
                WARN=$(grep "${WARNING}" ${LOGFILE} | grep -c ch4)
                ERR=$(grep "${ERROR}" ${LOGFILE} | grep -c ch4)
                mv ${LOGFILE} logs2/failed/${COMPILER}
                printf "|%-10s|%-10s|%-60s|%-10s|%-5s|%-5s|\n" $COUNT:$pid ${COMPILER} ${LIBRARY} "FAIL" ${WARN} ${ERR}
            fi
            COUNT=$((COUNT+1))
        done
    ) &
    pid0=$!
    wait ${pid0}
done
wait
echo "|----------|----------|------------------------------------------------------------|----------|-----|-----|"

