#!/usr/bin/env bash

trap "kill 0" SIGINT

if [ $# -lt 1 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 <gnu|intel>"
    exit
fi

killtree() {
    local pid=$1 child
    for child in $(pgrep -P $pid); do
        killtree $child
    done
    if [ $pid -ne $$ ];then
        kill -kill $pid 2> /dev/null
    fi
}

if [ ! "$2" ];then
    HOSTS="f055,f056"
else
    HOSTS="$2"
fi

if [ ! "$3" ];then
    PLOTS="plots"
else
    PLOTS="$3"
fi

export TASKS_PER_NODE_FULL=68
export TASKS_FULL=136
export TASKS_2=2
export TASKS_PER_NODE_2=1
export STASKS="SLURM_TASKS_PER_NODE='68(x2)'"
export OMPI_HOSTS=${HOSTS//,/:${TASKS_PER_NODE_FULL},}
export OMPI_HOSTS=${OMPI_HOSTS/%/:${TASKS_PER_NODE_FULL}}

#export PSM_FLOW_CREDITS=1024
#export PSM_MQ_RECVREQS_MAX=65536
#export PSM_MQ_SENDREQS_MAX=65536
#export PSM_NUM_SEND_BUFFERS=16384
#export PSM_NUM_SEND_DESCRIPTORS=16384
#export PSM_MQ_RNDV_IPATH_THRESH=0
#export PSM_MQ_RNDV_SHM_THRESH=0
#export PSM_MQ_EAGER_SDMA_SZ=0
#export PSM_VERBOSE_ENV=1
#HYDRA_TOPO_DEBUG=1
BENCHMARKS="pt2pt/osu_latency \
            pt2pt/osu_mbw_mr \
            pt2pt/osu_multi_lat \
            pt2pt/osu_latency_mt \
            pt2pt/osu_bibw \
            pt2pt/osu_bw \
            one-sided/osu_acc_latency \
            one-sided/osu_cas_latency \
            one-sided/osu_fop_latency \
            one-sided/osu_get_acc_latency \
            one-sided/osu_get_bw \
            one-sided/osu_get_latency \
            one-sided/osu_put_bibw \
            one-sided/osu_put_bw \
            one-sided/osu_put_latency \
            collective/osu_allgatherv \
            collective/osu_allreduce \
            collective/osu_alltoall \
            collective/osu_alltoallv \
            collective/osu_barrier \
            collective/osu_bcast \
            collective/osu_gather \
            collective/osu_gatherv \
            collective/osu_iallgather \
            collective/osu_iallgatherv \
            collective/osu_ialltoall \
            collective/osu_ialltoallv \
            collective/osu_ialltoallw \
            collective/osu_ibarrier \
            collective/osu_ibcast \
            collective/osu_igather \
            collective/osu_igatherv \
            collective/osu_iscatter \
            collective/osu_iscatterv \
            collective/osu_reduce \
            collective/osu_reduce_scatter \
            collective/osu_scatter \
            collective/osu_scatterv
"


#BENCHMARKS=pt2pt/osu_mbw_mr
#BENCHMARKS="pt2pt/osu_latency"
#BENCHMARKS="pt2pt/osu_latency"
#BENCHMARKS="pt2pt/osu_mbw_mr"
#BENCHMARKS="one-sided/osu_put_latency"
#BENCHMARKS="pt2pt/osu_mbw_mr
#            pt2pt/osu_multi_lat \
#            pt2pt/osu_latency_mt \
#            pt2pt/osu_bibw \
#            pt2pt/osu_bw \
#            pt2pt/osu_latency"
#BENCHMARKS="one-sided/osu_put_bw one-sided/osu_get_bw"
#BENCHMARKS="pt2pt/osu_bibw one-sided/osu_put_bibw"
#BENCHMARKS="one-sided/osu_cas_latency"

#BENCHMARKS="pt2pt/osu_latency"
BENCHMARKS_OMPI="$BENCHMARKS"
BENCHMARKS_DISABLED="
            collective/osu_reduce_scatter \
            "
AFFINITY_CHECK="~/affinity"
PLATFORMS="ch4_ofi_psm2_ts ch4_ofi_psm2_tpo ch4_ofi_psm2_tg ompi_system_psm2 ompi_ofi_psm2 mvapich_psm2 mvapich_system_psm2 impi_psm2 impi_ofi_psm2 ch3_ofi_psm2_ts ch3_ofi_psm2_tg "
#PLATFORMS=mvapich_system_psm2
#PLATFORMS=ch3_ofi_psm2_ts
#PLATFORMS="ch4_base_ts"
#PLATFORMS="ompi_base"
#PLATFORMS="mvapich_psm2"
#PLATFORMS="ompi_stock ompi_base"

BINDIR_BASE=/home/cjarcher/code/install
EXE_BASE=/home/cjarcher/code/osu/stage
LOG_BASE=/home/cjarcher/code/osu/${PLOTS}
TIMEOUT=300
COMPILER=$1

declare -A MPIEXEC_FLAVORS
declare -A ENV_FLAVORS
declare -A BIND_FLAVORS
declare -A BASEDIR_FLAVORS
declare -A BENCHMARK_NP
declare -A BENCHMARK_ARG
declare -A BENCHMARK_SLURM
declare -A BENCHMARK_LIST
declare -A PRINT_RANK
declare -A PERNODE

MPIEXEC_FLAVORS=( ["mvapich_psm2"]="${BINDIR_BASE}/${COMPILER}/mvapich-optimized-base/bin/mpiexec.hydra"
                  ["mvapich_system_psm2"]="/usr/mpi/gcc/mvapich2-2.1-hfi/bin/mpirun"
                  ["ch3_ofi_psm2_ts"]="${BINDIR_BASE}/${COMPILER}/optimized-ch3-ts-inline-ep-indirect-embedded-map-disabled-tagged-base/bin/mpiexec.hydra"
                  ["ch3_ofi_psm2_tg"]="${BINDIR_BASE}/${COMPILER}/optimized-ch3-tg-inline-ep-indirect-embedded-map-disabled-tagged-base/bin/mpiexec.hydra"
                  ["ch4_ofi_psm2_tpo"]="${BINDIR_BASE}/${COMPILER}/optimized-ofi-tpo-inline-ep-indirect-embedded-map-disabled-tagged-base/bin/mpiexec.hydra"
                  ["ch4_ofi_psm2_tg"]="${BINDIR_BASE}/${COMPILER}/optimized-ofi-tg-inline-ep-indirect-embedded-map-disabled-tagged-base/bin/mpiexec.hydra"
                  ["ch4_ofi_psm2_ts"]="${BINDIR_BASE}/${COMPILER}/optimized-ofi-ts-inline-ep-indirect-embedded-map-disabled-tagged-base/bin/mpiexec.hydra"
                  ["ompi_ofi_psm2"]="${BINDIR_BASE}/${COMPILER}/openmpi-optimized-base/bin/mpirun"
		          ["ompi_system_psm2"]="/usr/mpi/gcc/openmpi-1.10.2-hfi/bin/mpirun"
                  ["impi_psm2"]="/opt/intel/impi/2017/intel64/bin/mpiexec.hydra"
                  ["impi_ofi_psm2"]="/opt/intel/impi/2017/intel64/bin/mpiexec.hydra"
                )
ENV_FLAVORS=( ["mvapich_psm2"]=""
              ["mvapich_system_psm2"]=""
              ["ch3_ofi_psm2_ts"]="  MXM_LOG_LEVEL=error MPICH_NEMESIS_NETMOD=ofi"
              ["ch3_ofi_psm2_tg"]="  MXM_LOG_LEVEL=error MPICH_NEMESIS_NETMOD=ofi"
              ["ch4_ofi_psm2_tpo"]=""
              ["ch4_ofi_psm2_tg"]=""
              ["ch4_ofi_psm2_ts"]=""
              ["ompi_ofi_psm2"]=""
	          ["ompi_system_psm2"]=""
              ["impi_psm2"]=" I_MPI_PIN_DOMAIN=core TMI_CONFIG=/home/cjarcher/tmi.config I_MPI_FABRICS=tmi I_MPI_PLATFORM=bdw"
              ["impi_ofi_psm2"]=" I_MPI_PIN_DOMAIN=core I_MPI_OFI_LIBRARY=/home/cjarcher/code/install/gnu/ofi-optimized-base/lib/libfabric.so I_MPI_FABRICS=ofi I_MPI_PLATFORM=bdw"
            )

BIND_FLAVORS=( ["mvapich_psm2"]="-bind-to core -map-by core -launcher ssh -hosts ${HOSTS}"
               ["mvapich_system_psm2"]="-bind-to core -map-by core -launcher ssh -hosts ${HOSTS}"
               ["ch3_ofi_psm2_ts"]="-bind-to core -map-by core -launcher ssh -hosts ${HOSTS}"
               ["ch3_ofi_psm2_tg"]="-bind-to core -map-by core -launcher ssh -hosts ${HOSTS}"
               ["ch4_ofi_psm2_tpo"]="-bind-to core -map-by core -launcher ssh -host ${HOSTS}"
               ["ch4_ofi_psm2_tg"]="-bind-to core -map-by core -launcher ssh -host ${HOSTS}"
               ["ch4_ofi_psm2_ts"]="-bind-to core -map-by core -launcher ssh -host ${HOSTS}"
               ["ompi_ofi_psm2"]="--quiet --mca mtl ofi --mca pml cm -hostfile host.list -x PSM_PKEY=0x8001 -x MXM_LOG_LEVEL=error --bind-to core --map-by core:oversubscribe"
	           ["ompi_system_psm2"]="--quiet --mca mtl psm2 --mca pml cm -host ${HOSTS} -x PSM_PKEY=0x8001 -x MXM_LOG_LEVEL=error --bind-to core --map-by core:oversubscribe"
               ["impi_psm2"]="-hosts ${HOSTS}"
               ["impi_ofi_psm2"]="-hosts ${HOSTS}"
             )
BASEDIR_FLAVORS=( ["mvapich_psm2"]="${EXE_BASE}/${COMPILER}/mvapich_base/mpi"
                  ["mvapich_system_psm2"]="${EXE_BASE}/${COMPILER}/mvapich_stock/mpi"
                  ["ch3_ofi_psm2_ts"]="${EXE_BASE}/${COMPILER}/ch3_base_ts/mpi"
                  ["ch3_ofi_psm2_tg"]="${EXE_BASE}/${COMPILER}/ch3_base_tg/mpi"
                  ["ch4_ofi_psm2_tpo"]="${EXE_BASE}/${COMPILER}/ch4_base_tpo/mpi/"
                  ["ch4_ofi_psm2_tg"]="${EXE_BASE}/${COMPILER}/ch4_base_tg/mpi/"
                  ["ch4_ofi_psm2_ts"]="${EXE_BASE}/${COMPILER}/ch4_base_ts/mpi/"
                  ["ompi_ofi_psm2"]="${EXE_BASE}/${COMPILER}/ompi_base/mpi/"
		          ["ompi_system_psm2"]="${EXE_BASE}/${COMPILER}/ompi_stock/mpi/"
                  ["impi_psm2"]="${EXE_BASE}/${COMPILER}/impi_base/mpi/"
                  ["impi_ofi_psm2"]="${EXE_BASE}/${COMPILER}/impi_base/mpi/"
                )
BENCHMARK_NP=( ["pt2pt/osu_mbw_mr"]="${TASKS_FULL} "
               ["collective/osu_allgatherv"]="${TASKS_FULL}  "
               ["collective/osu_allreduce"]="${TASKS_FULL}  "
               ["collective/osu_alltoall"]="${TASKS_FULL}  "
               ["collective/osu_alltoallv"]="${TASKS_FULL}  "
               ["collective/osu_barrier"]="${TASKS_FULL}  "
               ["collective/osu_bcast"]="${TASKS_FULL}  "
               ["collective/osu_gather"]="${TASKS_FULL}  "
               ["collective/osu_gatherv"]="${TASKS_FULL}  "
               ["collective/osu_reduce"]="${TASKS_FULL}  "
               ["collective/osu_reduce_scatter"]="${TASKS_FULL}  "
               ["collective/osu_scatter"]="${TASKS_FULL}  "
               ["collective/osu_scatterv"]="${TASKS_FULL}  "
               ["collective/osu_iallgather"]="${TASKS_FULL}  "
               ["collective/osu_iallgatherv"]="${TASKS_FULL}  "
               ["collective/osu_ialltoall"]="${TASKS_FULL}  "
               ["collective/osu_ialltoallv"]="${TASKS_FULL}  "
               ["collective/osu_ialltoallw"]="${TASKS_FULL}  "
               ["collective/osu_ibarrier"]="${TASKS_FULL}  "
               ["collective/osu_ibcast"]="${TASKS_FULL}  "
               ["collective/osu_igather"]="${TASKS_FULL}  "
               ["collective/osu_igatherv"]="${TASKS_FULL}  "
               ["collective/osu_iscatter"]="${TASKS_FULL}  "
               ["collective/osu_iscatterv"]="${TASKS_FULL}  "
             )
BENCHMARK_ARG=( ["pt2pt/osu_mbw_mr"]="-w 64"
                ["pt2pt/osu_latency"]="-i 100000"
                ["one-sided/osu_acc_latency"]="-s flush"
                ["one-sided/osu_cas_latency"]="-s flush"
                ["one-sided/osu_fop_latency"]="-s flush"
                ["one-sided/osu_get_acc_latency"]="-s flush"
                ["one-sided/osu_get_bw"]="-s flush"
                ["one-sided/osu_get_latency"]="-s flush"
                ["one-sided/osu_put_bibw"]="-s fence"
                ["one-sided/osu_put_bw"]="-s flush"
                ["one-sided/osu_put_latency"]="-s flush"
              )
BENCHMARK_SLURM=( ["pt2pt/osu_mbw_mr"]="${STASKS}"
                  ["collective/osu_alltoallv"]="${STASKS}"
                  ["collective/osu_allgatherv"]="${STASKS}"
                  ["collective/osu_gatherv"]="${STASKS}"
                  ["collective/osu_reduce"]="${STASKS}"
                  ["collective/osu_barrier"]="${STASKS}"
                  ["collective/osu_reduce_scatter"]="${STASKS}"
                  ["collective/osu_scatterv"]="${STASKS}"
                  ["collective/osu_allreduce"]="${STASKS}"
                  ["collective/osu_alltoall"]="${STASKS}"
                  ["collective/osu_bcast"]="${STASKS}"
                  ["collective/osu_gather"]="${STASKS}"
                  ["collective/osu_allgather"]="${STASKS}"
                  ["collective/osu_scatter"]="${STASKS}"
                  ["collective/osu_iallgather"]="${STASKS}  "
                  ["collective/osu_iallgatherv"]="${STASKS}  "
                  ["collective/osu_ialltoall"]="${STASKS}  "
                  ["collective/osu_ialltoallv"]="${STASKS}  "
                  ["collective/osu_ialltoallw"]="${STASKS}  "
                  ["collective/osu_ibarrier"]="${STASKS}  "
                  ["collective/osu_ibcast"]="${STASKS}  "
                  ["collective/osu_igather"]="${STASKS}  "
                  ["collective/osu_igatherv"]="${STASKS}  "
                  ["collective/osu_iscatter"]="${STASKS}  "
                  ["collective/osu_iscatterv"]="${STASKS}  "
                )

BENCHMARK_LIST=( ["mvapich_psm2"]="${BENCHMARKS}"
                 ["mvapich_system_psm2"]="${BENCHMARKS}"
                 ["ch3_ofi_psm2_ts"]="${BENCHMARKS}"
                 ["ch3_ofi_psm2_tg"]="${BENCHMARKS}"
                 ["ch4_ofi_psm2_tpo"]="${BENCHMARKS}"
                 ["ch4_ofi_psm2_tg"]="${BENCHMARKS}"
                 ["ch4_ofi_psm2_ts"]="${BENCHMARKS}"
                 ["ompi_ofi_psm2"]="${BENCHMARKS_OMPI}"
		         ["ompi_system_psm2"]="${BENCHMARKS_OMPI}"
                 ["impi_psm2"]="${BENCHMARKS}"
                 ["impi_ofi_psm2"]="${BENCHMARKS}"
               )
PRINT_RANK=( ["mvapich_psm2"]="-prepend-rank"
             ["mvapich_system_psm2"]="-prepend-rank"
             ["ch3_ofi_psm2_ts"]="-prepend-rank"
             ["ch3_ofi_psm2_tg"]="-prepend-rank"
             ["ch4_ofi_psm2_tpo"]="-prepend-rank"
             ["ch4_ofi_psm2_tg"]="-prepend-rank"
             ["ch4_ofi_psm2_ts"]="-prepend-rank"
             ["ompi_ofi_psm2"]="-tag-output"
             ["ompi_system_psm2"]="-tag-output"
             ["impi_psm2"]="-prepend-rank"
             ["impi_ofi_psm2"]="-prepend-rank"
           )

PERNODE=( ["mvapich_psm2"]="-ppn"
          ["mvapich_system_psm2"]="-ppn"
          ["ch3_ofi_psm2_ts"]="-ppn"
          ["ch3_ofi_psm2_tg"]="-ppn"
          ["ch4_ofi_psm2_tpo"]="-ppn"
          ["ch4_ofi_psm2_tg"]="-ppn"
          ["ch4_ofi_psm2_ts"]="-ppn"
          ["ompi_ofi_psm2"]=""
	      ["ompi_system_psm2"]=""
          ["impi_psm2"]="-ppn"
          ["impi_ofi_psm2"]="-ppn"
        )

mkdir -p ${PLOTS}
rm    -f ${PLOTS}/*
#set +bm
set +bm
for platform in ${PLATFORMS}; do
    echo "$platform"
    GO_BENCHMARKS=${BENCHMARK_LIST["$platform"]}
    for bench in $GO_BENCHMARKS; do
        NP=${BENCHMARK_NP["$bench"]}
        if [ "$NP" == "" ] ;then
            NP="2"
        fi
        let TASKS_PER_NODE="$NP/2"
	    TPN=""
        if [ ! -z "${PERNODE["${platform}"]}" ]; then
            TPN="${PERNODE["${platform}"]} ${TASKS_PER_NODE}"
        fi
        ARG=${BENCHMARK_ARG["$bench"]}
        SLURMENV=${BENCHMARK_SLURM["$bench"]}
        LOGFILE=${LOG_BASE}/$(basename $bench).${platform}.out
        LOGFILEERR=${LOG_BASE}/$(basename $bench).${platform}.err
        cmdaffinity="${SLURMENV} ${ENV_FLAVORS["$platform"]} ${MPIEXEC_FLAVORS["${platform}"]} ${BIND_FLAVORS["${platform}"]} -np $NP ${TPN} ~/affinity"
        cmd="${SLURMENV} ${ENV_FLAVORS["${platform}"]} ${MPIEXEC_FLAVORS["${platform}"]} ${BIND_FLAVORS["${platform}"]} -np $NP ${TPN} ${BASEDIR_FLAVORS["${platform}"]}/$bench ${ARG}"
        echo \# ${platform},$bench:  $cmd >> ${LOGFILE}
        echo -e "${platform}"             >> ${LOGFILE}
        (tail -f ${LOGFILE}) &
        pid0=$!
        eval $cmdaffinity 2>&1 | sort | sed 's/^/# /g' 1>> ${LOGFILE} 2>> ${LOGFILEERR}
        (
            if [ "$COMPILER" == "intel" ]; then
                LD_LIBRARY_PATH=
                if [ "$platform" == "mvapich_system_psm2" ]; then
                    . /opt/intel/composer_xe_2015.3.187/bin/compilervars.sh intel64
                else
                    . ${HOME}/intel_compilervars.sh intel64
                    export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | sed -e 's/\/opt\/intel\/compilers_and_libraries_2016.3.210\/linux\/mpi\/intel64\/lib//')
                    export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | sed -e 's/\/opt\/intel\/compilers_and_libraries_2016.2.181\/linux\/mpi\/intel64\/lib//')
                fi
            else
                LD_LIBRARY_PATH=
            fi
            eval $cmd 2>&1 1>> ${LOGFILE} 2>> ${LOGFILEERR}
            sleep 1
        ) &
        pid1=$!
        (sleep ${TIMEOUT}; killtree ${pid1}; echo "KILLED pid ${pid1}")  &
        pid2=$!
        wait ${pid1} 2>/dev/null
        killtree ${pid0} 2>/dev/null
        killtree ${pid1} 2>/dev/null
        killtree ${pid2} 2>/dev/null
        wait  ${pid0} ${pid1} ${pid2} 2>/dev/null
        wait 2>/dev/null
    done
done

exit
