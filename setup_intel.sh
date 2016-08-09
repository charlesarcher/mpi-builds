#!/bin/sh

export AR=xiar
export LD="xild -qlink-name=/home/cjarcher/tools/x86/bin/ld"
export CC=icc
export CXX=icpc
export F77=ifort
export FC=ifort

# CPU Optimizations ###############
export HASWELL_OPT="-xCORE-AVX2 -fma"
export SILVERMONT_OPT="-xATOM_SSE4.2"
export KNL_OPT="-xMIC-AVX512 -DHAVE_AVX512"
export GENERIC_OPT="-msse2 -msse4.2 -mcrc32 -mavx2 -mtune=generic"

###################################
#export CPU_OPT=${GENERIC_OPT}
#export CPU_OPT=${SILVERMONT_OPT}
#export CPU_OPT=${KNL_OPT}
export CPU_OPT=${GENERIC_OPT}
export AR=xiar
export LD=xild
export CC=icc
export CXX=icpc
export EXTRA_OPT="-falign-functions=16"
export EXTRA_OPT="${EXTRA_OPT} -ipo"
export EXTRA_OPT="${EXTRA_OPT} -inline-factor=10000"
export EXTRA_OPT="${EXTRA_OPT} -inline-min-size=0"
export EXTRA_OPT="${EXTRA_OPT} -ansi-alias"
export EXTRA_OPT="${EXTRA_OPT} ${CPU_OPT}"
export EXTRA_LD_OPT="-ipo -qopt-report-phase=ipo -qopt-report=5"
export EXTRA_LD_OPT="${EXTRA_LD_OPT} ${CPU_OPT}"
export EXTRA_DEBUG="${CPU_OPT}"

# -wd869:  parameter X was never referenced
# -wd280:  selector expression is constant
# -wd593:  vari able "c" was set but never use
# -wd2259: non-pointer conversion from A to B may lose precision
# -wd981:  operands are evaluated in unspecified order
export WALLC="-Wcheck -Wall -w3 -wd869 -wd280 -wd593 -wd2259 -wd981"
export WALLF="-w"
