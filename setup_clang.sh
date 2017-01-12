#!/bin/sh

if /bin/false ; then
    export AR='/home/cjarcher/tools/x86/bin/clang-ar'
    export NM='nm --plugin /home/cjarcher/tools/x86/lib/LLVMgold.so'
    export LD='/home/cjarcher/tools/x86/bin/ld --plugin /home/cjarcher/tools/x86/lib/LLVMgold.so'
    export CC='clang --gcc-toolchain=/opt/rh/devtoolset-4/root/usr/'
    export CXX='clang++ --gcc-toolchain=/opt/rh/devtoolset-4/root/usr/'
    export F77="gfortran"
    export FC="gfortran"
    export EXTRA_DEBUG=""
    export FLTO_OPT="-flto"
    export FLTO_LD="-O4 -Wl,-plugin,/home/cjarcher/tools/x86/lib/LLVMgold.so"
    export EXTRA_OPT="${EXTRA_OPT} ${FLTO_OPT}"
    export EXTRA_OPT="${EXTRA_OPT} ${CPU_OPT}"
    export EXTRA_LD_OPT="${CPU_OPT} ${FLTO_OPT} ${FLTO_LD}"
    export RANLIB=':'
    #export SCAN_BUILD="scan-build"
else
    export AR="ar"
    export LD="ld"
    export CC="clang -fno-vectorize -fno-slp-vectorize"
    export CXX="clang++ -fno-vectorize -fno-slp-vectorize"
    export F77="gfortran"
    export FC="gfortran"
    export WALLC="-Wall -Weverything"
    export WALLF="-Wall"
fi
