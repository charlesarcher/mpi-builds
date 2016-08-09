#!/bin/sh

trap "kill 0" SIGINT

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

#FULL BUILD SET:  LOTS OF BUILDS!!!!
OPTIMIZATIONS="optimized debug"
ADITYPES="stub ofi"
THREADMODELS="ts tg tpo"
ADIINLINERS="inline noinline"
EPTYPES="sep ep"
PROVTYPES="direct dynamic"
COLLINLINES="dynamic ctree cstub cdefault"
COLLTSPINLINES="dynamic ctspmpich"

#BUILD SUBSET
OPTIMIZATIONS="debug optimized"
ADITYPES="ofi"
THREADMODELS="tpo"
ADIINLINERS="noinline inline"
EPTYPES="sep ep"
PROVTYPES="dynamic"
#COLLINLINES="ctree"
#COLLTSPINLINES="ctspmpich"
COLLINLINES="dynamic"
COLLTSPINLINES="dynamic"

for optimization in ${OPTIMIZATIONS}; do
    for aditype in ${ADITYPES}; do
        for threadmodel in ${THREADMODELS}; do
            for adiinliner in ${ADIINLINERS}; do
                for eptype in ${EPTYPES}; do
                    for provtype in ${PROVTYPES}; do
                        for collinline in ${COLLINLINES}; do
                            for colltspinline in ${COLLTSPINLINES}; do
                                LIBRARIES="${LIBRARIES} ${optimization}-${aditype}-${threadmodel}-${adiinliner}-${eptype}-${provtype}-${collinline}-${colltspinline}"
                            done
                        done
                    done
                done
            done
        done
    done
done
LIBRARIES="${LIBRARIES} debug opt"
COMPILERS="gnu intel clang"
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

echo "|----------|----------|------------------------------------------------------------|----------|"
printf "|%-10s|%-10s|%-60s|%-10s|\n" "PID" "COMPILER" "BUILD" "STATUS"
echo "|----------|----------|------------------------------------------------------------|----------|"
COUNT=1
for COMPILER in ${COMPILERS}; do
    (
	for LIBRARY in ${LIBRARIES}; do
	    if [ "${LIBRARY}" == "debug" ]; then
		LOGFILE=logs/${COMPILER}.netmod.${LIBRARY}.log
		(sh ./build-netmod.sh ${COMPILER} debug ${LIBRARY} > ${LOGFILE}   2>&1)&
	    elif [ "${LIBRARY}" == "opt" ]; then
		LOGFILE=logs/${COMPILER}.netmod.${LIBRARY}.log
		(sh ./build-netmod.sh ${COMPILER} opt ${LIBRARY} > ${LOGFILE}   2>&1)&
	    else
		LOGFILE=logs/${COMPILER}.${LIBRARY}.log
		(sh ./build.sh ${COMPILER} ${LIBRARY} > ${LOGFILE} 2>&1)&
	    fi
	    pid=$!
	    wait ${pid}
	    if [ $? -eq 0 ]; then
		mv ${LOGFILE} logs/success/${COMPILER}
		printf "|%-10s|%-10s|%-60s|%-10s|\n" $COUNT:$pid ${COMPILER} ${LIBRARY} "SUCCESS"
	    else
		mv ${LOGFILE} logs/failed/${COMPILER}
		printf "|%-10s|%-10s|%-60s|%-10s|\n" $COUNT:$pid ${COMPILER} ${LIBRARY} "FAIL"
	    fi
	    COUNT=$((COUNT+1))
	done
    ) &
    pid0=$!
    wait ${pid0}
done
wait

echo "|----------|----------|------------------------------------------------------------|----------|"

