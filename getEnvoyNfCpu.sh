#!/usr/bin/env bash

commonTZ="MDT"
exp=/opt/Results

declare -a networkFunctions=("amfd" "smfd" "ausfd" "bsfd" "nrfd" "nssfd" "pcfd" "udmd" "udrd")
declare -a workerNodes=("1" "2" "5" "6" "7" "8" "9" "10" "11")
declare -a experimentDirAry=("secure")

for f1 in "${experimentDirAry[@]}"
do
    echo "Working on $exp/$f1"
    echo " "
    subexp=800
    if [[ $f1 == "secure" ]]; then
        jarray=(1 4 5 9)
    fi
    for j in ${jarray[@]}
    do
        arrayIndex=0
        for nf in ${networkFunctions[@]}
        do
            nfTopFile=$exp/$f1-$j/$subexp/top_data_node${workerNodes[arrayIndex]}.txt
            topCpuOpFile=$exp/$f1-$j/$subexp/topCpuOpEnvoy$nf$j.csv
            rm -f $topCpuOpFile
            
            echo "Working on $topCpuOpFile"
            sjCount=$(cat $nfTopFile | grep systemd-journal | wc -l)
            echo "UTC-Time, Time-Diff, $nf-CPU-Usage, envoy-CPU-Usage" >> $topCpuOpFile
            timestamps=( $(cat $nfTopFile | grep 2023- | grep -o '\-\-.*' | cut -c 3-) )
            if (( $sjCount < 5 )); then
                timestamps=("${timestamps[@]:1}")
            fi
            cpusage=( $(cat $nfTopFile | grep open5gs-$nf | awk '{print $9}') )
            cat $nfTopFile | grep -e 2023- -e envoy | awk {'print $9'} > /tmp/uk1
            if [[ $arrayIndex == 0 ]]; then
                cpusage2=( $(awk 'NF==0{n=0;next} n<2{arr[++n]=$0} n==2{printf arr[1]+arr[2] "\n"; n=0}' /tmp/uk1) )
            else
                cpusage2=( $(awk 'NF==0{n=0;next} n<1{arr[++n]=$0} n==1{printf arr[1] "\n"; n=0}' /tmp/uk1) )
            fi
            basecpu="0.0"
            k=0
            for i in "${!cpusage[@]}";
            do
                mdtTs=${timestamps[$i]}
                if [[ $k == 0 ]]; then
                    firstTs=$(TZ=$commonTZ date -d "$mdtTs MDT - 0.2 second"  +'%T.%3N')
                    firstEpochTs=$(date -d "$firstTs" +"%s.%3N")
                    echo "$firstTs, 0, $basecpu" >> $topCpuOpFile
                fi
                utcTs=$(TZ=$commonTZ date -d "$mdtTs MDT"  +'%T.%3N')
                epochTs=$(date -d "$utcTs" +"%s.%3N")
                timediff=$(echo -e "$epochTs-$firstEpochTs" | bc)
                timediff=$(echo -e "$timediff*1000" | bc | rev | cut -c 5- | rev)
                echo "$utcTs, $timediff, ${cpusage[$i]}, ${cpusage2[$i]}" >> $topCpuOpFile
                k=$k+1
                
            done
            utcTs=$(TZ=$commonTZ date -d "$mdtTs MDT + 0.2 second"  +'%T.%3N')
            epochTs=$(date -d "$utcTs" +"%s.%3N")
            timediff=$(echo -e "$epochTs-$firstEpochTs" | bc)
            timediff=$(echo -e "$timediff*1000" | bc | rev | cut -c 5- | rev)
            echo "$utcTs, $timediff, $basecpu, $basecpu" >> $topCpuOpFile
            
            rm -f /tmp/utcTs.txt
            rm -f /tmp/uk1
            rm -f /tmp/queuelens.txt
            echo "Completed processing files from $exp/$f1-$j/$subexp/"
            echo " "
            arrayIndex=$((arrayIndex + 1))
        done
    done
done