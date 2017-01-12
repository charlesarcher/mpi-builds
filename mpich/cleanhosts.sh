#!/bin/sh

#HOSTS="f009 f010 f012 f013 f027 f028"
HOSTS="f055 f056 f057 f058"
#HOSTS="f014 f015 f016 f017 f027 f028"
HOSTS_ARRAY=($HOSTS)

echo -n "Running on hosts:  "
for HOST in "${HOSTS_ARRAY[@]}"; do
    echo -n "${HOST} " #=${HOST_AVAILABLE[${HOST}]}
done
echo ""


#for HOST in "${HOSTS_ARRAY[@]}"; do
#    echo -n "${HOST} :" #=${HOST_AVAILABLE[${HOST}]}
#    cmd="ssh ${HOST} 'sh ~/killall.sh'"
#    echo $cmd
#    eval $cmd &
#done
#wait

for HOST in "${HOSTS_ARRAY[@]}"; do
    echo -n "${HOST} :" #=${HOST_AVAILABLE[${HOST}]}
    cmd="ssh ${HOST} rm -rf /work/cjarcher/stage \; ls /work/cjarcher"
    echo $cmd
    eval $cmd &
done
wait
