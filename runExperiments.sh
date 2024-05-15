#!/usr/bin/env bash

if [[ $# -ne 1 ]] ; then
    echo "Expected 1 CLI argument - Experiment directory"
    exit 1
fi

experimentDirPrefix="$1"

#0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17
#0 - master
#1-11 - worker
#12,14 - gnb
#13,15 - UE

#mongoPod=`kubectl -n open5gs get po -o json |  jq '.items[] | select(.metadata.name|contains("open5gs"))| .metadata.name' | grep "mongo" | sed 's/"//g'`
#kubectl exec -it $mongoPod -- bash -c "apt-get update && apt -y install git vim python3-pip && git clone https://github.com/UmakantKulkarni/scripts"

mkdir -p /opt/Experiments/

#declare -a subDir=("100" "200" "300" "400" "500" "600" "700" "800" "900" "1000")
declare -a subDir=("100" "200" "300" "400")

declare -a experimentDirAry=("$experimentDirPrefix-1" "$experimentDirPrefix-2" "$experimentDirPrefix-3" "$experimentDirPrefix-4" "$experimentDirPrefix-5" "$experimentDirPrefix-6" "$experimentDirPrefix-7" "$experimentDirPrefix-8" "$experimentDirPrefix-9" "$experimentDirPrefix-10")

declare -a ueNodes=("10.10.1.2" "10.10.1.3")

for experimentDir in "${experimentDirAry[@]}"
do
    for pcsDir in "${subDir[@]}"
    do
        
        echo "Sub-dir is $pcsDir"
        rm -rf /opt/Experiments/${experimentDir}/${pcsDir}
        mkdir -p /opt/Experiments/${experimentDir}/${pcsDir}
        
        numSessions=$(( pcsDir / 1 ))
        callTime=$(( pcsDir / 4 ))
        
        #cleanup
        kubectl get pods --no-headers=true | awk '/upf|amf|bsf|pcf|udm|ausf|nrf|nssf|udr|smf/{print $1}'| xargs  kubectl delete pod
        
        sleep 60
        
        #start-ztx
        bash /opt/scripts/runNodeCmd.sh "mkdir -p /opt/Experiments/${experimentDir}" 1 2
        bash /opt/scripts/runNodeCmd.sh "mkdir -p /opt/Experiments/${experimentDir}/${pcsDir}" 1 2
        
        ranCount=1
        for ueNodeIp in "${ueNodes[@]}"
        do
            bash /opt/scripts/runNodeCmd.sh "ztx -i $ueNodeIp -z 1 > /opt/Experiments/${experimentDir}/${pcsDir}/ztx_ran.log 2>&1 &" $ranCount
            #ztx -i 10.10.1.2 -z 1 > /opt/Experiments/${experimentDir}/${pcsDir}/ztx_ran.log 2>&1 &
            ranCount=$((ranCount+1))
        done
        sleep 5

        #start-ran
        bash /opt/scripts/runNodeCmd.sh "nr-gnb -c /opt/UERANSIM/config/open5gs-gnb.yaml > /dev/null 2>&1 &" 1 2
        #nr-gnb -c /opt/UERANSIM/config/open5gs-gnb.yaml > /dev/null 2>&1 &

        bash /opt/scripts/startTopVm.sh $experimentDir $pcsDir
        bash /opt/scripts/startTopNode.sh $experimentDir $pcsDir 1 2
        
        #rm -rf /opt/Experiments/$experimentDir/$pcsDir/istioPerf
        #mkdir -p /opt/Experiments/$experimentDir/$pcsDir/istioPerf
        PODARRAY=()
        for pod in `kubectl -n open5gs get po -o json |  jq '.items[] | select(.metadata.name|contains("open5gs"))| .metadata.name' | grep -v "test\|webui\|upf\|mongo" | sed 's/"//g'` ;
        do
            echo $pod
            PODARRAY+=($pod)
        done
        
        #https://github.com/istio/istio/wiki/Analyzing-Istio-Performance
        # for pod in "${PODARRAY[@]}"
        # do  
        #     POD=$pod
        #     NS=open5gs
        #     PROFILER="cpu" # Can also be "heap", for a heap profile
        #     kubectl exec -n "$NS" "$POD" -c istio-proxy -- curl -X POST -s "http://localhost:15000/${PROFILER}profiler?enable=y"
        #     PROFILER="heap" # Can also be "heap", for a heap profile
        #     kubectl exec -n "$NS" "$POD" -c istio-proxy -- curl -X POST -s "http://localhost:15000/${PROFILER}profiler?enable=y"
        # done
        
        #bash /opt/scripts/runNodeCmd.sh "/opt/scripts/launchUeSim.py > /dev/null 2>&1 &" 1
        #/opt/scripts/launchUeSim.py > /dev/null 2>&1 &
        
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
        #cd /opt/Experiments/${experimentDir}/${pcsDir} && nr-ue -c /opt/UERANSIM/config/open5gs-ue.yaml -n $numSessions > /opt/Experiments/${experimentDir}/${pcsDir}/uesim.logs 2>&1 &
        
        sleep $callTime
        cd /opt/scripts
        
        #stop-monitoring
        bash /opt/scripts/stopTopVm.sh
        bash /opt/scripts/stopTopNode.sh 1 2
        bash /opt/scripts/savePodLogs.sh $experimentDir $pcsDir
        
        #sleep 60
        
        # for pod in "${PODARRAY[@]}"
        # do
        #     POD=$pod
        #     NS=open5gs
        #     nfName=$(echo $pod | awk -v FS="(open5gs-|-deployment)" '{print $2}')
        #     mkdir -p /opt/Experiments/$experimentDir/$pcsDir/istioPerf/${nfName}
        #     PROFILER="cpu" # Can also be "heap", for a heap profile
        #     kubectl exec -n "$NS" "$POD" -c istio-proxy -- curl -X POST -s "http://localhost:15000/${PROFILER}profiler?enable=n"
        #     PROFILER="heap" # Can also be "heap", for a heap profile
        #     kubectl exec -n "$NS" "$POD" -c istio-proxy -- curl -X POST -s "http://localhost:15000/${PROFILER}profiler?enable=n"
        #     kubectl cp -n "$NS" "$POD":/var/lib/istio/data /opt/Experiments/$experimentDir/$pcsDir/istioPerf/${nfName} -c istio-proxy
        #     #kubectl cp -n "$NS" "$POD":/lib/x86_64-linux-gnu /opt/Experiments/$experimentDir/$pcsDir/istioPerf/${nfName}/lib -c istio-proxy
        #     #kubectl cp -n "$NS" "$POD":/usr/local/bin/envoy /opt/Experiments/$experimentDir/$pcsDir/istioPerf/${nfName}/lib/envoy -c istio-proxy
        # done
        
        #stop-ran
        bash /opt/scripts/runNodeCmd.sh "pkill -f nr-ue" 1 2
        #pkill -f nr-ue
        
        sleep 5
        
        bash /opt/scripts/runNodeCmd.sh "pkill -f nr-gnb" 1 2
        #pkill -f nr-gnb
        
        sleep 5
        bash /opt/scripts/runNodeCmd.sh "pkill -f ztx" 1 2
        #pkill -f ztx
        
        sleep 5
        #bash /opt/scripts/runNodeCmd.sh "pkill -f launchUeSim" 1
        #pkill -f launchUeSim
        
        #sleep 5
        
        #kubectl exec -it $mongoPod -- bash -c "pkill -f mongoMonitor.py"
        
        #sleep 5
        
    done
done