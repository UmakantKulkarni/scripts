#!/usr/bin/env bash

declare -a NFs=("amf" "smf" "ausf" "bsf" "pcf" "nrf" "nssf" "udr" "udm")
exp="/opt/Experiments"
echo $exp
f1="IstioBench2"
for subexp in `seq 100 100 400`
do
    for j in `seq 1 1 1`
    do
        threshUeCount=$(echo "scale=4; $subexp*0.9" | bc)
        currUeCount=0
        ueLogFile=$exp/$f1-$j/$subexp/uesim.logs
        if [ -f "$ueLogFile" ] ; then
            currUeCount=$(cat $ueLogFile | grep 'PCS Skipped setting TUN interface for UE' | wc -l)
        fi
        if (( currUeCount >= threshUeCount )); then
            nfFile=$exp/$f1-$j/$subexp/nf_max_queue.txt
            for nf in "${NFs[@]}"
            do
                nfIstioLogFile=$exp/$f1-$j/$subexp/open5gs-${nf}-deployment-*_istio_logs.txt
                echo "Working on $nfIstioLogFile"
                LINE_NUM=$(grep -n "Envoy proxy is ready" $nfIstioLogFile | cut -d: -f1)
                tail -n +$((LINE_NUM + 1)) $nfIstioLogFile > $exp/$f1-$j/$subexp/${nf}IstioLogs.json
                sed -i '/Starting tracking the heap/d' $exp/$f1-$j/$subexp/${nf}IstioLogs.json
                sed -i '/^[[:space:]]*$/d' $exp/$f1-$j/$subexp/${nf}IstioLogs.json
            done
        fi
    done
done



