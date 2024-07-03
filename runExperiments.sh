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

declare -a subDir=("100" "200" "300" "400" "500" "600" "700" "800" "900" "1000")

declare -a experimentDirAry=("$experimentDirPrefix-1" "$experimentDirPrefix-2" "$experimentDirPrefix-3" "$experimentDirPrefix-4" "$experimentDirPrefix-5" "$experimentDirPrefix-6" "$experimentDirPrefix-7" "$experimentDirPrefix-8" "$experimentDirPrefix-9" "$experimentDirPrefix-10")

declare -a ueNodes=("198.22.255.16" "198.22.255.48")
declare -a gnbNodes=("198.22.255.49" "198.22.255.24")
declare -a ranNodes=("5" "7")

NAMESPACE="oai5gc"

bash /opt/scripts/runNodeCmd.sh "iptables -t mangle -A PREROUTING -p sctp -m mark ! --mark 15 -j NFQUEUE --queue-num 0 ; iptables -t mangle -A OUTPUT -p sctp -m mark ! --mark 15 -j NFQUEUE --queue-num 0" 5 7

for experimentDir in "${experimentDirAry[@]}"
do
    for pcsDir in "${subDir[@]}"
    do
        
        echo "Sub-dir is $pcsDir"
        rm -rf /opt/Experiments/${experimentDir}/${pcsDir}
        mkdir -p /opt/Experiments/${experimentDir}/${pcsDir}
        
        numSessions=$(( pcsDir / 1 ))
        #callTime=$(( pcsDir / 4 ))
        callTime=30
        
        #cleanup
        kubectl get pods -n $NAMESPACE --no-headers=true | awk '/nrf|nssf/{print $1}'| xargs  kubectl delete pod -n $NAMESPACE
        sleep 5
        kubectl get pods -n $NAMESPACE --no-headers=true | awk '/upf|amf|pcf|udm|ausf|udr|smf/{print $1}'| xargs  kubectl delete pod -n $NAMESPACE
        
        sleep 60
        
        bash /opt/scripts/runNodeCmd.sh "mkdir -p /opt/Experiments/${experimentDir}" 5 7
        bash /opt/scripts/runNodeCmd.sh "mkdir -p /opt/Experiments/${experimentDir}/${pcsDir}" 5 7
        
        #start-ztx
        ranCount=0
        for gnbNodeIp in "${gnbNodes[@]}"
        do
            bash /opt/scripts/runNodeCmd.sh "ztx -i $gnbNodeIp -z 1 > /opt/Experiments/${experimentDir}/${pcsDir}/ztx_ran.log 2>&1 &" ${ranNodes[ranCount]}
            #ztx -i 10.10.1.2 -z 1 > /opt/Experiments/${experimentDir}/${pcsDir}/ztx_ran.log 2>&1 &
            ranCount=$((ranCount+1))
        done
        sleep 5

        #start-ran
        bash /opt/scripts/runNodeCmd.sh "nr-gnb -c /opt/UERANSIM/config/oai-gnb.yaml > /dev/null 2>&1 &" 5 7
        #nr-gnb -c /opt/UERANSIM/config/open5gs-gnb.yaml > /dev/null 2>&1 &

        bash /opt/scripts/startTopNode.sh $experimentDir $pcsDir 0 1 2 3 5 6 7 8
        
        #rm -rf /opt/Experiments/$experimentDir/$pcsDir/istioPerf
        #mkdir -p /opt/Experiments/$experimentDir/$pcsDir/istioPerf
        PODARRAY=()
        for pod in `kubectl -n $NAMESPACE get po -o json |  jq '.items[] | select(.metadata.name|contains("oai"))| .metadata.name' | grep -v "test\|webui\|upf\|sql\|mongo" | sed 's/"//g'` ;
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
        bash /opt/scripts/stopTopNode.sh 0 1 2 3 5 6 7 8
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
        bash /opt/scripts/runNodeCmd.sh "pkill -f nr-ue" 6 8
        #pkill -f nr-ue
        
        sleep 5
        
        bash /opt/scripts/runNodeCmd.sh "pkill -f nr-gnb" 5 7
        #pkill -f nr-gnb
        
        sleep 5
        bash /opt/scripts/runNodeCmd.sh "pkill -f ztx" 5 7
        #pkill -f ztx
        
        sleep 5
        #bash /opt/scripts/runNodeCmd.sh "pkill -f launchUeSim" 1
        #pkill -f launchUeSim
        
        #sleep 5
        
        #kubectl exec -it $mongoPod -- bash -c "pkill -f mongoMonitor.py"
        
        #sleep 5
        
    done
done

bash /opt/scripts/runNodeCmd.sh "iptables -t mangle -D PREROUTING -p sctp -m mark ! --mark 15 -j NFQUEUE --queue-num 0 ; iptables -t mangle -D OUTPUT -p sctp -m mark ! --mark 15 -j NFQUEUE --queue-num 0" 5 7