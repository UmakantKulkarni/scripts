#!/usr/bin/env bash

if [[ $# -ne 1 ]] ; then
	echo "Expected 1 CLI argument - Experiment directory"
    exit 1
fi

experimentDirPrefix="$1"
numWorkerNodes=10

mongoPod=`kubectl -n open5gs get po -o json |  jq '.items[] | select(.metadata.name|contains("open5gs"))| .metadata.name' | grep "mongo" | sed 's/"//g'`
kubectl exec -it $mongoPod -- bash -c "apt-get update && apt -y install git vim python3-pip && git clone https://github.com/UmakantKulkarni/scripts"

declare -a subDir=("100" "200" "300" "400" "500" "600" "700" "800" "900" "1000")

declare -a experimentDirAry=("$experimentDirPrefix-1" "$experimentDirPrefix-2" "$experimentDirPrefix-3" "$experimentDirPrefix-4" "$experimentDirPrefix-5" "$experimentDirPrefix-6" "$experimentDirPrefix-7" "$experimentDirPrefix-8" "$experimentDirPrefix-9" "$experimentDirPrefix-10")

declare -a ueNodes=("10.10.1.13" "10.10.1.15")

for experimentDir in "${experimentDirAry[@]}"
do
    for pcsDir in "${subDir[@]}"
    do

        echo "Sub-dir is $pcsDir"
        numSessions=$(( pcsDir / 2 ))

        #cleanup
        kubectl get pods --no-headers=true | awk '/upf|amf|bsf|pcf|udm|ausf|nrf|nssf|udr|smf/{print $1}'| xargs  kubectl delete pod

        sleep 60


        #start-ran
        bash /opt/scripts/runNodeCmd.sh "nr-gnb -c /opt/UERANSIM/config/open5gs/gnb.yaml > /dev/null 2>&1 &" 11 13

        #bash /opt/scripts/runNodeCmd.sh "/opt/scripts/launchUeSim.py > /dev/null 2>&1 &" 12 14


        #start-monitoring
        #kubectl exec $mongoPod -- bash -c "/scripts/mongoMonitor.py" &
        mongoPodIp=$(kubectl get pod $mongoPod --template={{.status.podIP}})
        curl --verbose --request POST --header "Content-Type:application/json" --data '{"expDir":"'$experimentDir'","subExpDir":"'$pcsDir'","runTime":30}' http://$mongoPodIp:15692
        
        bash /opt/scripts/startTop.sh $numWorkerNodes $experimentDir $pcsDir


        #start-ue
        for ueNodeIp in "${ueNodes[@]}"
        do
            if (( pcsDir > 500 )); then
                sleep 0.3
            else
                sleep 0.2
            fi
            echo "UE-SIM IP Address is $ueNodeIp"
            curl --verbose --request POST --header "Content-Type:application/json" --data '{"numSessions":"'$numSessions'","expDir":"'$experimentDir'","subExpDir":"'$pcsDir'"}'  http://$ueNodeIp:15692
        done

        sleep 15


        #stop-monitoring
        bash /opt/scripts/stopTop.sh $numWorkerNodes

        bash /opt/scripts/savePodLogs.sh $experimentDir $pcsDir

        sleep 30

        #stop-ran
        bash /opt/scripts/runNodeCmd.sh "pkill -f nr-ue" 12 14

        sleep 5

        bash /opt/scripts/runNodeCmd.sh "pkill -f nr-gnb" 11 13

        sleep 5
        
        #bash /opt/scripts/runNodeCmd.sh "pkill -f launchUeSim.py" 12 14

        #sleep 5

        #kubectl exec -it $mongoPod -- bash -c "pkill -f mongoMonitor.py"

        #sleep 5

    done
done