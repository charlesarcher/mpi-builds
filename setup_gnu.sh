#!/bin/sh

export AR="gcc-ar"
export NM="gcc-nm"
export RANLIB="gcc-ranlib"
export LD="ld"
export CC="gcc"
export CXX="g++"
export F77="gfortran"
export FC="gfortran"
#export LD="/home/cjarcher/tools/x86/bin/ld"

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
export FLTO_OPT="-flto=32 -flto-partition=balanced"
export FLTO_OPT="${FLTO_OPT} --param inline-unit-growth=300"
export FLTO_OPT="${FLTO_OPT} --param ipcp-unit-growth=300"
export FLTO_OPT="${FLTO_OPT} --param large-function-insns=500000000"
export FLTO_OPT="${FLTO_OPT} --param large-function-growth=5000000000"
export FLTO_OPT="${FLTO_OPT} --param large-stack-frame-growth=5000000"
export FLTO_OPT="${FLTO_OPT} --param max-inline-insns-single=2147483647"
export FLTO_OPT="${FLTO_OPT} --param max-inline-insns-auto=2147483647"
export FLTO_OPT="${FLTO_OPT} --param inline-min-speedup=0"

#export FLTO_OPT="-flto=64 -flto-partition=max -ffat-lto-objects"
export FLTO_LD="-fuse-linker-plugin"
export EXTRA_OPT="-falign-functions -finline-limit=2147483647 ${CPU_OPT} ${FLTO_OPT}"
export EXTRA_LD_OPT="${CPU_OPT} ${FLTO_OPT} ${FLTO_LD}"
export EXTRA_LD_DEBUG="${CPU_OPT}"
export EXTRA_DEBUG="${CPU_OPT}"
export WALLC="-Wall"
export WALLF="-Wall"
