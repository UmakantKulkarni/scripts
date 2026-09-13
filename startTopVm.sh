#!/usr/bin/env bash

if [[ $# -ne 2 ]] ; then
	echo "Expected 2 CLI arguments - Sub-directory & experiment directory to save output"
    exit 1
fi

VM_PASSWORD="purdue@ztx"
declare -a vms=("master" "worker1" "worker2" "worker3" "worker4" "worker5")

experimentDir="$1"
pcsDir="$2"

ocmd="cd /opt/ && mkdir -p Experiments && cd Experiments && mkdir -p $experimentDir && cd $experimentDir && mkdir -p $pcsDir && cd $pcsDir && rm -f top_data_*.txt && (bash /opt/scripts/topFile.sh > /dev/null 2>&1 &)"
ktcmd="cd /opt/Experiments/$experimentDir/$pcsDir && rm -f kt_data.txt && (bash /opt/scripts/ktopFile.sh > /dev/null 2>&1 &)"
mcmd="$ktcmd && exit"
wcmd="$ocmd && exit"

dscmd="cd /opt/Experiments/$experimentDir/$pcsDir && rm -f docker_data_*.txt && (bash /opt/scripts/dockerStats.sh > /dev/null 2>&1 &)"
psscmd="cd /opt/Experiments/$experimentDir/$pcsDir && rm -f open5gs*_ss.txt && (bash /opt/scripts/ssPodOp.sh > /dev/null 2>&1 &)"
dswcmd="$dscmd && exit"

for vm in "${vms[@]}"
do
	vmip=$(timeout 5 setsid virsh domifaddr $vm | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
	echo ""
	echo "Starting top-start script on vm - $vm"
	echo ""
    if [ "$vm" = "master" ] ; then
        #eval "$dscmd"
        #eval "$psscmd"
        sshpass -p $VM_PASSWORD ssh -o StrictHostKeyChecking=no root@$vmip "$wcmd"
        sshpass -p $VM_PASSWORD ssh -o StrictHostKeyChecking=no root@$vmip "$mcmd"
    else
        #sshpass -p $VM_PASSWORD ssh -o StrictHostKeyChecking=no root@$vmip "$dswcmd"
        sshpass -p $VM_PASSWORD ssh -o StrictHostKeyChecking=no root@$vmip "$wcmd"
    fi
	echo ""
	echo "Started top-start script on vm - $vm"
    echo ""
done