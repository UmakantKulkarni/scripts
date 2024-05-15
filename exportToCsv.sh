#!/usr/bin/env bash

exp=/opt/Experiments
opFile=$exp/exp-data.csv
rm -f $opFile

declare -a experimentDirAry=("AllSecure" "CoreSecure" "PfcpSecure" "RanSecure" "Unsecured" "IstioSec")

echo "experiment,numSessions,run,ueSessCount,amfQueueLength,smfQueueLength,upfQueueLength,amfTimeTaken,smfTimeTaken,upfTimeTaken" >> $opFile
for f1 in "${experimentDirAry[@]}"
do  
    for subexp in `seq 100 100 400`
    do
        for j in `seq 1 1 10`
        do
            ueipn1File=$exp/$f1-$j/$subexp/pcs_ueips.txt_node1
            nfFile=$exp/$f1-$j/$subexp/nf_max_queue.txt
            if [ -f "$ueipn1File" ] && [ -f "$nfFile" ]; then
                ueSessCount=$(cat $ueipn1File | wc -l)
                amfQueueLength=$(cat $nfFile | grep amf | cut -d "," -f2)
                smfQueueLength=$(cat $nfFile | grep smf | cut -d "," -f2)
                upfQueueLength=$(cat $nfFile | grep upf | cut -d "," -f2)
                amfTimeTaken=$(printf '%.9f\n' $(cat $nfFile | grep amf | cut -d "," -f3))
                smfTimeTaken=$(printf '%.9f\n' $(cat $nfFile | grep smf | cut -d "," -f3))
                upfTimeTaken=$(printf '%.9f\n' $(cat $nfFile | grep upf | cut -d "," -f3))
                echo "$f1,$subexp,$j,$ueSessCount,$amfQueueLength,$smfQueueLength,$upfQueueLength,$amfTimeTaken,$smfTimeTaken,$upfTimeTaken" >> $opFile
            fi
        done
    done
done