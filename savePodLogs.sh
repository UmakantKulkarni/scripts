#!/usr/bin/env bash

if [[ $# -ne 2 ]] ; then
        echo "Expected 2 CLI arguments - sub-directory & experiment directory to save output"
    exit 1
fi

calc_sum() {
    log_file=$1
    op_file=$2
    param=$3
    total_time=$(awk "sub(/.*for transaction $param is: /, \"\") && sub(/ sec.*/, \"\")" $log_file | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}' | awk '{s+=$1} END {print s}')
    echo "$param,$total_time" >> $op_file
}

save_trans_times () {
    nf_name=$1
    log_file=$2
    op_file=$3
    if [[ "$nfName" == "amf" ]] ; then
        declare -a params=("CSCAmfReadIOTime" "CSCAmfReadSDTime" "CSCAmfWriteIOTime" "CSCAmfWriteSDTime" "N1N2AmfReadIOTime" "N1N2AmfReadSDTime" "N1N2AmfWriteIOTime" "N1N2AmfWriteSDTime" "USCAmfReadIOTime" "USCAmfReadSDTime" "USCAmfWriteIOTime" "USCAmfWriteSDTime")
    elif [[ "$nfName" == "smf" ]] ; then
        declare -a params=("CSCSmfReadIOTime" "CSCSmfReadSDTime" "CSCSmfWriteIOTime" "CSCSmfWriteSDTime" "N1N2SmfReadIOTime" "N1N2SmfReadSDTime" "N1N2SmfWriteIOTime" "N1N2SmfWriteSDTime" "USCSmfReadIOTime" "USCSmfReadSDTime" "USCSmfWriteIOTime" "USCSmfWriteSDTime" "PERSmfReadIOTime" "PERSmfReadSDTime" "PERSmfWriteIOTime" "PERSmfWriteSDTime")
    elif [[ "$nfName" == "upf" ]] ; then
        declare -a params=("CreateUpfReadIOTime" "CreateUpfReadSDTime" "CreateUpfWriteIOTime" "CreateUpfWriteSDTime" "UpdateUpfReadIOTime" "UpdateUpfReadSDTime" "UpdateUpfWriteIOTime" "UpdateUpfWriteSDTime")
    else
        return 1
    fi
    for tra in "${params[@]}"
    do
        calc_sum "$log_file" "$op_file" "$tra"
    done
    echo " " >> $op_file
}

experimentDir="$1"
pcsDir="$2"

ARRAY=()
for pod in `kubectl -n open5gs get po -o json |  jq '.items[] | select(.metadata.name|contains("open5gs"))| .metadata.name' | grep -v "test\|webui\|mongo" | sed 's/"//g'` ;
do
    echo $pod
    ARRAY+=($pod)
done

rm -f /opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt

for pod in "${ARRAY[@]}"
do
    rm -f /opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt
    #rm -f /opt/Experiments/$experimentDir/$pcsDir/${pod}_istio_logs.txt
    #rm -f /opt/Experiments/$experimentDir/$pcsDir/${pod}_ztx_logs.txt
    nfName=$(echo $pod | awk -v FS="(open5gs-|-deployment)" '{print $2}')
    kubectl logs $pod -n open5gs -c $nfName > /opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt
    #kubectl logs $pod -n open5gs -c ztx > /opt/Experiments/$experimentDir/$pcsDir/${pod}_ztx_logs.txt
    if [[ "$nfName" == "amf" ||  "$nfName" == "smf" ||  "$nfName" == "upf" ]] ; then
        echo ""
        #kubectl logs $pod -n open5gs -c istio-proxy > /opt/Experiments/$experimentDir/$pcsDir/${pod}_istio_logs.txt
    fi
    maxQueue=$(cat /opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt | grep " ogs_queue_size is" | grep "PCS " | awk '{print $9}' | sort -rn | head -n 1)
    if [[ "$nfName" == "amf" ]] ; then
        startTime=$(cat /opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt | grep InitialUEMessage | head -1 | awk '{print $2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        stopTime=$(cat /opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt | grep "UE SUPI\[imsi-" | tail -1 | awk '{print $2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        d1=$(date -d $startTime "+%s.%N")
        d2=$(date -d $stopTime "+%s.%N")
        timediff=$(echo "$d2 - $d1" | bc)
        echo "$nfName,$maxQueue,$timediff" >> /opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt
        echo " " >> /opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt
        #save_trans_times "$nfName" "/opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt" "/opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt"
    elif [[ "$nfName" == "smf" ]] ; then
        startTime=$(cat /opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt | grep "\[Added\] Number of SMF-UEs is now" | head -1 | awk '{print $2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        stopTime=$(cat /opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt | grep "UE SUPI\[imsi-" | tail -1 | awk '{print $2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        d1=$(date -d $startTime "+%s.%N")
        d2=$(date -d $stopTime "+%s.%N")
        timediff=$(echo "$d2 - $d1" | bc)
        echo "$nfName,$maxQueue,$timediff" >> /opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt
        echo " " >> /opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt
        #save_trans_times "$nfName" "/opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt" "/opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt"
    elif [[ "$nfName" == "upf" ]] ; then
        startTime=$(cat /opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt | grep "\[Added\] Number of UPF-Sessions is now" | head -1 | awk '{print $2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        stopTime=$(cat /opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt | grep "UE F-SEID\[UP:" | tail -1 | awk '{print $2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        d1=$(date -d $startTime "+%s.%N")
        d2=$(date -d $stopTime "+%s.%N")
        timediff=$(echo "$d2 - $d1" | bc)
        echo "$nfName,$maxQueue,$timediff" >> /opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt
        echo " " >> /opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt
        #save_trans_times "$nfName" "/opt/Experiments/$experimentDir/$pcsDir/${pod}_logs.txt" "/opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt"
    else
        echo "$nfName,$maxQueue" >> /opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt
        echo " " >> /opt/Experiments/$experimentDir/$pcsDir/nf_max_queue.txt
    fi
done