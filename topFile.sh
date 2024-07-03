#!/usr/bin/env bash
Hostname=$(hostname --short)
while true
do
        echo " " >> top_data_$Hostname.txt
        date +"%F--%T.%N" >> top_data_$Hostname.txt
        pids=( $(top -b -n 1 | grep "oai\|docker\|kube\|calico\|container\|etcd\|istio\|vpn\|nr\|envoy\|sql\|ztx" | awk '{print $1}') )
        numpids=${#pids[@]}
        topcmd="top -b -n 1"
        for i in "${pids[@]}"
        do
            topcmd="$topcmd -p $i"
        done
        COLUMNS=500 $topcmd >> top_data_$Hostname.txt 2>&1 &
        echo " " >> top_data_$Hostname.txt
        #sleep 0.1
done