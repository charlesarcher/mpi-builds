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
    HOSTS="f027,f028"
else
    HOSTS="$2"
fi

if [ ! "$3" ];then
    PLOTS="plots"
else
    PLOTS="$3"
fi

export TASKS_PER_NODE_FULL=72
export TASKS_FULL=144
export TASKS_2=2
export TASKS_PER_NODE_2=1
export STASKS="SLURM_TASKS_PER_NODE='18(x2)'"


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
BENCHMARKS="pt2pt/osu_mbw_mr \
            pt2pt/osu_latency \
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
            collective/osu_alltoallv \
            collective/osu_allgatherv \
            collective/osu_gatherv \
            collective/osu_reduce \
            collective/osu_barrier \
            collective/osu_scatterv \
            collective/osu_allreduce \
            collective/osu_alltoall \
            collective/osu_bcast \
            collective/osu_gather \
            collective/osu_allgather \
            collective/osu_scatter \
            collective/osu_ialltoallv \
            collective/osu_iallgatherv \
            collective/osu_igatherv \
            collective/osu_ireduce \
            collective/osu_ibarrier \
            collective/osu_iscatterv \
            collective/osu_iallreduce \
            collective/osu_ialltoall \
            collective/osu_ibcast \
            collective/osu_igather \
            collective/osu_iallgather \
            collective/osu_iscatter \
"
#BENCHMARKS=pt2pt/osu_mbw_mr"
#BENCHMARKS="one-sided/osu_put_latency"
#BENCHMARKS="pt2pt/osu_latency"
#BENCHMARKS="pt2pt/osu_mbw_mr pt2pt/osu_latency"
#BENCHMARKS="one-sided/osu_cas_latency"
BENCHMARKS_OMPI="$BENCHMARKS"
BENCHMARKS_DISABLED="
            collective/osu_reduce_scatter \
            "
AFFINITY_CHECK="~/affinity"
PLATFORMS="ch4_psm2 ch4_opa netmod_ofi_psm2 ompi_ofi ompi_psm mvapich_psm impi_psm ompi_stock_psm mvapich_stock_psm"
#PLATFORMS="ch4"
#PLATFORMS=ch4
#PLATFORMS="ompi_stock_psm mvapich_stock_psm"
#" ompi_psm ompi_ofi"
COMPILER=$1
BINDIR_BASE=/home/cjarcher/code/install
EXE_BASE=/home/cjarcher/code/osu/stage
LOG_BASE=/home/cjarcher/code/osu/${PLOTS}
TIMEOUT=300

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

MPIEXEC_FLAVORS=( ["mvapich_psm"]="${BINDIR_BASE}/${COMPILER}/mvapich-optimized-psm2/bin/mpiexec.hydra"
		          ["mvapich_stock_psm"]="/usr/mpi/gcc/mvapich2-2.1-hfi/bin/mpiexec.hydra"
                  ["mvapich_ib"]="${BINDIR_BASE}/${COMPILER}/mvapich-ib/bin/mpiexec.hydra"
                  ["netmod_ofi_base"]="${BINDIR_BASE}/${COMPILER}/netmod-optimized-base/bin/mpiexec.hydra"
                  ["netmod_ofi_psm2"]="${BINDIR_BASE}/${COMPILER}/netmod-optimized-psm2/bin/mpiexec.hydra"
                  ["netmod_mxm_base"]="${BINDIR_BASE}/${COMPILER}/netmod-optimized-base/bin/mpiexec.hydra"
                  ["ch4_psm2"]="${BINDIR_BASE}/${COMPILER}/optimized-ofi-tpo-inline-ep-dynamic-static-map-disabled-psm2/bin/mpiexec.hydra"
                  ["ch4_opa"]="${BINDIR_BASE}/${COMPILER}/optimized-ofi-tpo-inline-ep-dynamic-static-map-disabled-opa/bin/mpiexec.hydra"
                  ["ompi_ofi"]="${BINDIR_BASE}/${COMPILER}/openmpi-optimized-psm2/bin/mpirun"
                  ["ompi_psm"]="${BINDIR_BASE}/${COMPILER}/openmpi-optimized-psm2/bin/mpirun"
		          ["ompi_stock_psm"]="/usr/mpi/gcc/openmpi-1.10.0-hfi/bin/mpirun"
                  ["ompi_mxm"]="${BINDIR_BASE}/${COMPILER}/openmpi-optimized-psm2/bin/mpirun"
                  ["ompi_ib"]="${BINDIR_BASE}/${COMPILER}/openmpi-optimized-psm2/bin/mpirun"
                  ["impi_psm"]="/opt/intel/impi/5.0.3.048/intel64/bin/mpiexec.hydra"
                  ["impi_ib"]="/opt/intel/impi/5.0.3.048/intel64/bin/mpiexec.hydra"
                )
ENV_FLAVORS=( ["mvapich_psm"]=""
	          ["mvapich_stock_psm"]=""
              ["mvapich_ib"]="MV2_IBA_HCA=mlx4_0"
              ["netmod_ofi_base"]=" MXM_LOG_LEVEL=error MPICH_NEMESIS_NETMOD=ofi"
              ["netmod_ofi_psm2"]=" MXM_LOG_LEVEL=error MPICH_NEMESIS_NETMOD=ofi"
              ["netmod_mxm_base"]=" MXM_LOG_LEVEL=error MPICH_NEMESIS_NETMOD=mxm"
              ["ch4_psm2"]=""
              ["ch4_opa"]=""
              ["ompi_psm"]=""
	          ["ompi_stock_psm"]=""
              ["ompi_ofi"]=""
              ["ompi_mxm"]=""
              ["impi_psm"]="I_MPI_PIN_DOMAIN=core LD_LIBRARY_PATH=/usr/lib64/psm2-compat  TMI_CONFIG=/home/cjarcher/tmi.config I_MPI_FABRICS=tmi"
              ["impi_ib"]="I_MPI_PIN_DOMAIN=core"
            )

BIND_FLAVORS=( ["mvapich_psm"]="-bind-to core -map-by core -launcher ssh -hosts ${HOSTS}"
	           ["mvapich_stock_psm"]="-bind-to core -map-by core -launcher ssh -hosts ${HOSTS}"
               ["mvapich_ib"]="-bind-to core -map-by core -launcher ssh -hosts ${HOSTS}"
               ["netmod_ofi_base"]="-bind-to core -map-by core -launcher ssh -hosts ${HOSTS}"
               ["netmod_ofi_psm2"]="-bind-to core -map-by core -launcher ssh -hosts ${HOSTS}"
               ["netmod_mxm_base"]="-bind-to core -map-by core -launcher ssh -hosts ${HOSTS}"
               ["ch4_psm2"]="-bind-to core -map-by core -launcher ssh -host ${HOSTS}"
               ["ch4_opa"]="-bind-to core -map-by core -launcher ssh -host ${HOSTS}"
               ["ompi_psm"]="--quiet --mca mtl psm2 --mca pml cm -host ${HOSTS} -x PSM_PKEY=0x8001 -x MXM_LOG_LEVEL=error --bind-to core --map-by core"
	           ["ompi_stock_psm"]="--quiet --mca mtl psm2 --mca pml cm -host ${HOSTS} -x PSM_PKEY=0x8001 -x MXM_LOG_LEVEL=error --bind-to core --map-by core"
               ["ompi_ofi"]="--quiet --mca mtl ofi --mca pml cm -host ${HOSTS} -x MXM_LOG_LEVEL=error --bind-to core --map-by core"
               ["ompi_mxm"]="--quiet --mca pml yalla -host ${HOSTS} -x MXM_LOG_LEVEL=error --bind-to core --map-by core"
               ["ompi_ib"]="--quiet --mca btl openib,self,sm -host ${HOSTS} -x MXM_LOG_LEVEL=error --bind-to core --map-by core"
               ["impi_psm"]="-hosts ${HOSTS}"
               ["impi_ib"]="-hosts ${HOSTS}"
             )
BASEDIR_FLAVORS=( ["mvapich_psm"]="${EXE_BASE}/${COMPILER}/mvapich/mpi"
		          ["mvapich_stock_psm"]="${EXE_BASE}/${COMPILER}/mvapich_stock/mpi"
                  ["mvapich_ib"]="${EXE_BASE}/${COMPILER}/mvapich-ib/mpi"
                  ["netmod_ofi_base"]="${EXE_BASE}/${COMPILER}/netmod-ofi-base/mpi"
                  ["netmod_ofi_psm2"]="${EXE_BASE}/${COMPILER}/netmod-ofi-psm2/mpi"
                  ["netmod_mxm_base"]="${EXE_BASE}/${COMPILER}/netmod-ofi-base/mpi"
                  ["ch4_psm2"]="${EXE_BASE}/${COMPILER}/ch4_psm2/mpi/"
                  ["ch4_opa"]="${EXE_BASE}/${COMPILER}/ch4_opa/mpi/"
                  ["ompi_psm"]="${EXE_BASE}/${COMPILER}/ompi/mpi/"
		          ["ompi_stock_psm"]="${EXE_BASE}/${COMPILER}/ompi_stock/mpi/"
                  ["ompi_ofi"]="${EXE_BASE}/${COMPILER}/ompi/mpi/"
                  ["ompi_mxm"]="${EXE_BASE}/${COMPILER}/ompi/mpi/"
                  ["ompi_ib"]="${EXE_BASE}/${COMPILER}/ompi/mpi/"
                  ["impi_psm"]="${EXE_BASE}/${COMPILER}/impi/mpi/"
                  ["impi_ib"]="${EXE_BASE}/${COMPILER}/impi/mpi/"
                )
BENCHMARK_NP=( ["pt2pt/osu_mbw_mr"]="${TASKS_FULL} "
               ["collective/osu_alltoallv"]="${TASKS_FULL}  "
               ["collective/osu_allgatherv"]="${TASKS_FULL}  "
               ["collective/osu_gatherv"]="${TASKS_FULL}  "
               ["collective/osu_reduce"]="${TASKS_FULL}  "
               ["collective/osu_barrier"]="${TASKS_FULL}  "
               ["collective/osu_reduce_scatter"]="${TASKS_FULL}  "
               ["collective/osu_scatterv"]="${TASKS_FULL}  "
               ["collective/osu_allreduce"]="${TASKS_FULL}  "
               ["collective/osu_alltoall"]="${TASKS_FULL}  "
               ["collective/osu_bcast"]="${TASKS_FULL}  "
               ["collective/osu_gather"]="${TASKS_FULL}  "
               ["collective/osu_allgather"]="${TASKS_FULL}  "
               ["collective/osu_scatter"]="${TASKS_FULL}  "
             )
BENCHMARK_ARG=( ["pt2pt/osu_mbw_mr"]="-w 64"
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
                )

BENCHMARK_LIST=( ["mvapich_psm"]="${BENCHMARKS}"
		         ["mvapich_stock_psm"]="${BENCHMARKS}"
                 ["mvapich_ib"]="${BENCHMARKS}"
                 ["netmod_ofi_base"]="${BENCHMARKS}"
                 ["netmod_ofi_psm2"]="${BENCHMARKS}"
                 ["netmod_mxm_base"]="${BENCHMARKS}"
                 ["ch4_psm2"]="${BENCHMARKS}"
                 ["ch4_opa"]="${BENCHMARKS}"
                 ["ompi_psm"]="${BENCHMARKS_OMPI}"
		         ["ompi_stock_psm"]="${BENCHMARKS_OMPI}"
                 ["ompi_ofi"]="${BENCHMARKS_OMPI}"
                 ["ompi_mxm"]="${BENCHMARKS_OMPI}"
                 ["ompi_ib"]="${BENCHMARKS_OMPI}"
                 ["impi_psm"]="${BENCHMARKS}"
                 ["impi_ib"]="${BENCHMARKS}"
               )
PRINT_RANK=( ["mvapich_psm"]="-prepend-rank"
	         ["mvapich_stock_psm"]="-prepend-rank"
             ["mvapich_ib"]="-prepend-rank"
             ["netmod_ofi_base"]="-prepend-rank"
             ["netmod_ofi_psm2"]="-prepend-rank"
             ["netmod_mxm_base"]="-prepend-rank"
             ["ch4_psm2"]="-prepend-rank"
             ["ch4_opa"]="-prepend-rank"
             ["ompi_psm"]="-tag-output"
	         ["ompi_stock_psm"]="-tag-output"
             ["ompi_ofi"]="-tag-output"
             ["ompi_mxm"]="-tag-output"
             ["ompi_ib"]="-tag-output"
             ["impi_psm"]="-prepend-rank"
             ["impi_ib"]="-prepend-rank"
           )

PERNODE=( ["mvapich_psm"]="-ppn"
	      ["mvapich_stock_psm"]="-ppn"
          ["mvapich_ib"]="-ppn"
          ["netmod_ofi_base"]="-ppn"
          ["netmod_ofi_psm2"]="-ppn"
          ["netmod_mxm_base"]="-ppn"
          ["ch4_psm2"]="-ppn"
          ["ch4_opa"]="-ppn"
          ["ompi_psm"]=""
	      ["ompi_stock_psm"]=""
          ["ompi_ofi"]=""
          ["ompi_mxm"]=""
          ["ompi_ib"]=""
          ["impi_psm"]="-ppn"
          ["impi_ib"]="-ppn"
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
        (eval $cmd 2>&1 1>> ${LOGFILE} 2>> ${LOGFILEERR}) &
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
