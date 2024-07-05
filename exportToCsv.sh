#!/usr/bin/env bash

exp=/opt/Experiments
opFile=$exp/exp-data.csv
rm -f $opFile

declare -a experimentDirAry=("allSecure" "coreSecure" "pfcpSecure" "ranSecure" "unsecured" "istioSec")

echo "experiment,numSessions,run,UePassed,UeFailed,AverageTotalRegTime,AverageRegReqAuthReq,AverageAuthRspSecMReq,AverageSecModeRspICReq,AverageTotalPduEstTime,AveragePduSessReqAccept,amfQueueLength,smfQueueLength,upfQueueLength,amfTimeTaken,smfTimeTaken,upfTimeTaken" >> $opFile
for f1 in "${experimentDirAry[@]}"
do  
    for subexp in `seq 100 100 1000`
    do
        for j in `seq 1 1 10`
        do
            gnbLogFIle=$exp/$f1-$j/$subexp/gnb.log_node5
            nfFile=$exp/$f1-$j/$subexp/nf_max_queue.txt
            if [ -f "$gnbLogFIle" ] && [ -f "$nfFile" ]; then
                gnbRes=$(parse_log_file $gnbLogFIle)
                ueSessCount=$(cat $ueipn1File | wc -l)
                amfQueueLength=$(cat $nfFile | grep amf | cut -d "," -f2)
                smfQueueLength=$(cat $nfFile | grep smf | cut -d "," -f2)
                upfQueueLength=$(cat $nfFile | grep upf | cut -d "," -f2)
                amfTimeTaken=$(printf '%.9f\n' $(cat $nfFile | grep amf | cut -d "," -f3))
                smfTimeTaken=$(printf '%.9f\n' $(cat $nfFile | grep smf | cut -d "," -f3))
                upfTimeTaken=$(printf '%.9f\n' $(cat $nfFile | grep upf | cut -d "," -f3))
                echo "$f1,$subexp,$j,$gnbRes,$amfQueueLength,$smfQueueLength,$upfQueueLength,$amfTimeTaken,$smfTimeTaken,$upfTimeTaken" >> $opFile
            fi
        done
    done
done

# Function to parse log file and return required data
parse_log_file() {
    log_file=$1

    # Initialize variables
    UePassed=0
    UeFailed=0

    total_reg_time=0
    reg_req_auth_req=0
    auth_rsp_sec_mreq=0
    sec_mode_rsp_ic_req=0
    total_pdu_est_time=0
    pdu_sess_req_accept=0

    total_reg_time_count=0
    reg_req_auth_req_count=0
    auth_rsp_sec_mreq_count=0
    sec_mode_rsp_ic_req_count=0
    total_pdu_est_time_count=0
    pdu_sess_req_accept_count=0


    # Regex patterns
    ue_pattern="Ue's Passed: ([0-9]+) , Ue's Failed: ([0-9]+)"
    reg_time_pattern="TotalRegTime\[us\]: ([0-9]+), RegReqAuthReq\[us\]: ([0-9]+),  AuthRspSecMReq\[us\]: ([0-9]+), SecModeRspICReq\[us\]: ([0-9]+)"
    pdu_est_pattern="TotalPduEstTime\[us\]: ([0-9]+), PduSessReqAccept\[us\]: ([0-9]+)"

    # Read the log file line by line
    while IFS= read -r line; do
        if [[ $line =~ $ue_pattern ]]; then
            UePassed=${BASH_REMATCH[1]}
            UeFailed=${BASH_REMATCH[2]}
        elif [[ $line =~ $reg_time_pattern ]]; then
            total_reg_time=$((total_reg_time + ${BASH_REMATCH[1]}))
            reg_req_auth_req=$((reg_req_auth_req + ${BASH_REMATCH[2]}))
            auth_rsp_sec_mreq=$((auth_rsp_sec_mreq + ${BASH_REMATCH[3]}))
            sec_mode_rsp_ic_req=$((sec_mode_rsp_ic_req + ${BASH_REMATCH[4]}))

            total_reg_time_count=$((total_reg_time_count + 1))
            reg_req_auth_req_count=$((reg_req_auth_req_count + 1))
            auth_rsp_sec_mreq_count=$((auth_rsp_sec_mreq_count + 1))
            sec_mode_rsp_ic_req_count=$((sec_mode_rsp_ic_req_count + 1))
        elif [[ $line =~ $pdu_est_pattern ]]; then
            total_pdu_est_time=$((total_pdu_est_time + ${BASH_REMATCH[1]}))
            pdu_sess_req_accept=$((pdu_sess_req_accept + ${BASH_REMATCH[2]}))

            total_pdu_est_time_count=$((total_pdu_est_time_count + 1))
            pdu_sess_req_accept_count=$((pdu_sess_req_accept_count + 1))
        fi
    done < "$log_file"

    # Calculate averages
    AverageTotalRegTime=$((total_reg_time / total_reg_time_count))
    AverageRegReqAuthReq=$((reg_req_auth_req / reg_req_auth_req_count))
    AverageAuthRspSecMReq=$((auth_rsp_sec_mreq / auth_rsp_sec_mreq_count))
    AverageSecModeRspICReq=$((sec_mode_rsp_ic_req / sec_mode_rsp_ic_req_count))
    AverageTotalPduEstTime=$((total_pdu_est_time / total_pdu_est_time_count))
    AveragePduSessReqAccept=$((pdu_sess_req_accept / pdu_sess_req_accept_count))

    # Print results
    # echo "UePassed: $UePassed"
    # echo "UeFailed: $UeFailed"
    # echo "AverageTotalRegTime: $AverageTotalRegTime"
    # echo "AverageRegReqAuthReq: $AverageRegReqAuthReq"
    # echo "AverageAuthRspSecMReq: $AverageAuthRspSecMReq"
    # echo "AverageSecModeRspICReq: $AverageSecModeRspICReq"
    # echo "AverageTotalPduEstTime: $AverageTotalPduEstTime"
    # echo "AveragePduSessReqAccept: $AveragePduSessReqAccept"

    echo "$UePassed,$UeFailed,$AverageTotalRegTime,$AverageRegReqAuthReq,$AverageAuthRspSecMReq,$AverageSecModeRspICReq,$AverageTotalPduEstTime,$AveragePduSessReqAccept"
}
