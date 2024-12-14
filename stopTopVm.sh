#!/usr/bin/env bash

VM_PASSWORD="purdue@ztx"
declare -a vms=("master" "worker1" "worker2" "worker3" "worker4" "worker5")

ocmd="pkill -f topFile.sh"
ktcmd="pkill -f ktopFile.sh"
dscmd="pkill -f dockerStats.sh"
psscmd="pkill -f ssPodOp.sh"

mcmd="$ktcmd && exit"
wcmd="$ocmd && exit"
dswcmd="$dscmd && exit"

for vm in "${vms[@]}"
do
	vmip=$(timeout 5 setsid virsh domifaddr $vm | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
	echo ""
	echo "Stopping top-start script on vm - $vm"
	echo ""
    if [ "$vm" = "master" ] ; then
        #eval "$ocmd"
        #eval "$ktcmd"
        #eval "$dscmd"
        #eval "$psscmd"
        sshpass -p $VM_PASSWORD ssh -o StrictHostKeyChecking=no root@$vmip "$wcmd"
        sshpass -p $VM_PASSWORD ssh -o StrictHostKeyChecking=no root@$vmip "$mcmd"
    else
        sshpass -p $VM_PASSWORD ssh -o StrictHostKeyChecking=no root@$vmip "$wcmd"
        #sshpass -p $VM_PASSWORD ssh -o StrictHostKeyChecking=no root@$vmip "$dswcmd"
    fi
	echo ""
	echo "Stopped top-start script on vm - $vm"
    echo ""
done