#!/usr/bin/env bash

ARRAY=()
for pod in `kubectl -n open5gs get po -o json |  jq '.items[] | select(.metadata.name|contains("open5gs"))| .metadata.name' | grep -v "test\|webui" | sed 's/"//g'` ;
do
    #echo $pod
    ARRAY+=($pod)
done

while true
do
    for pod in "${ARRAY[@]}"
    do
        echo " " >> ${pod}_ss.txt && date +"%F--%T.%N" >> ${pod}_ss.txt && (kubectl -n open5gs exec $pod -- bash -c "ss -ti" >> ${pod}_ss.txt 2>&1 &)
    done
    sleep 0.2
done