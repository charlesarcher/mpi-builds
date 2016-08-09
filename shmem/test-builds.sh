#!/bin/sh

trap "kill 0" SIGINT

mkdir -p logs

(sleep 1;
 (sh ./build.sh intel  > logs/intel.log   2>&1)&
 pid=$!
 echo "$pid: building Intel:  "
 wait
) &
pid0=$!

(sleep 1;
 (sh ./build.sh gnu > logs/gnu.log   2>&1)&
 pid=$!
 echo "$pid: building GNU:  "
 wait
) &
pid1=$!

(sleep 1;
 (sh ./build.sh clang  > logs/clang.log   2>&1)&
 pid=$!
 echo "$pid: building CLANG:"
 wait
) &
pid2=$!

wait
echo "Done with builds $pid0 $pid1 $pid2"
