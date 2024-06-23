#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
	echo "Expected at least 1 CLI argument - Interface name"
    exit 1
fi

intf="$1"
masterNode="0"
declare -a workerNodes=("1" "2" "3")
declare -a ranNodes=("4" "5" "6" "7")
declare -a allK8Nodes=("0" "1" "2" "3" "4" "5" "6" "7")

#https://computingforgeeks.com/deploy-kubernetes-cluster-on-ubuntu-with-kubeadm/
#https://computingforgeeks.com/install-mirantis-cri-dockerd-as-docker-engine-shim-for-kubernetes/
#https://www.tutorialworks.com/difference-docker-containerd-runc-crio-oci/

#cri_socket="unix:///var/run/crio/crio.sock"
#cri_socket="unix:///run/containerd/containerd.sock"
#cri_socket="unix:///run/cri-dockerd.sock"

for nodeNum in "${allK8Nodes[@]}"
do
	node=node$nodeNum
    echo ""
    echo "Preparing K8s node $node"
    echo ""
	ssh -o StrictHostKeyChecking=no root@$node "cd /opt/scripts && git pull"
	ssh -o StrictHostKeyChecking=no root@$node "bash /opt/scripts/updateK8Nodes.sh"
    echo ""
    echo "Prepared node"
    echo ""
done

echo "Waiting for 30 seconds..."
sleep 30


echo ""
echo "Configuring Master Node"
echo ""

mcmd="cd /opt/scripts/ && bash /opt/scripts/configMasterNode.sh $intf"
ssh -o StrictHostKeyChecking=no root@node$masterNode "$mcmd"
kjoincmdorig="kubeadm token create --print-join-command"
kjoincmd=$(ssh -o StrictHostKeyChecking=no root@node$masterNode "$kjoincmdorig")

echo ""
echo "Finished Configuring Master Node. Sleep for 30 seconds..."
echo ""

sleep 30

echo ""
echo "Configuring Worker Nodes with command - $kjoincmd"
echo ""


wcmd="cd /opt/scripts/ && bash /opt/scripts/configWorkerNode.sh \"$kjoincmd\" && exit"
for nodeNum in "${workerNodes[@]}"
do	
	node=node$nodeNum
	echo ""
	echo "Configuring Node - $node"
	echo ""
	ssh -o StrictHostKeyChecking=no root@$node "$wcmd"
	echo ""
	echo "Finished Configuring Worker Node - $node"
    echo ""
done

echo ""
echo "Finished Configuring Worker Nodes"
echo ""


echo ""
echo "Started Configuring RAN Nodes"
echo ""

rcmd="cd /opt/scripts/ && bash /opt/scripts/configRanNode.sh && exit"
for nodeNum in "${ranNodes[@]}"
do	
	node=node$nodeNum
	echo ""
	echo "Configuring Node - $node"
	echo ""
	ssh -o StrictHostKeyChecking=no root@$node "$rcmd"
	echo ""
	echo "Finished Configuring RAN Node - $node"
	echo ""
done

echo ""
echo "Finished Configuring RAN Nodes"
echo ""


echo "Waiting for 60 seconds..."
sleep 60

restart_cmd="systemctl restart containerd"
for nodeNum in "${workerNodes[@]}"
do	
	node=node$nodeNum
    echo ""
    echo "Executing restart comand on Worker node $node"
    echo ""
    ssh -o StrictHostKeyChecking=no root@$node $restart_cmd
    echo ""
    echo "Finished Executing comand"
    echo ""
done


echo "Waiting 200 seconds for nodes to be ready..."
sleep 30
mcmd="kubectl taint nodes $(kubectl get nodes --selector=node-role.kubernetes.io/control-plane | awk 'FNR==2{print $1}') node-role.kubernetes.io/control-plane-"
ssh -o StrictHostKeyChecking=no root@node$masterNode "$mcmd"
sleep 170

echo ""
echo "Started K8s cluster"
echo ""
