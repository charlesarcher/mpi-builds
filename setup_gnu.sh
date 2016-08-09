#!/bin/sh

export AR="ar"
export LD="/home/cjarcher/tools/x86/bin/ld"
export CC="gcc"
export CXX="g++"
export F77="gfortran"
export FC="gfortran"

# CPU Optimizations ###############
export HASWELL_OPT="-march=haswell"
export SILVERMONT_OPT="-march=silvermont"
export KNL_OPT="-march=silvermont -mavx512f -mavx2"
export GENERIC_OPT="-msse2 -msse4.2 -mcrc32 -mavx2 -mtune=generic"
###################################

export CPU_OPT=${GENERIC_OPT}
#export CPU_OPT=${SILVERMONT_OPT}
#export CPU_OPT=${KNL_OPT}
#export CPU_OPT=${HASWELL_OPT}
#export EXTRA_OPT="-falign-functions=16 -falign-loops=16 -finline-limit=268435456 ${FLTO_OPT} ${CPU_OPT}"
export FLTO_OPT="-flto -ffat-lto-objects"
export FLTO_LD="-fuse-linker-plugin"
export EXTRA_OPT="-falign-functions -finline-limit=536870912 ${CPU_OPT} ${FLTO_OPT}"
export EXTRA_LD_OPT="${CPU_OPT} ${FLTO_OPT} ${FLTO_LD}"
export EXTRA_LD_DEBUG="${FLTO_LD} ${CPU_OPT}"
export EXTRA_DEBUG="${FLTO_OPT} ${CPU_OPT}"
export WALLC="-Wall"
export WALLF="-Wall"
