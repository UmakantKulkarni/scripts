#!/usr/bin/env bash

DEBIAN_FRONTEND=noninteractive
WORKDIR=/tmp
cd $WORKDIR

VM_USERNAME=root
VM_PASSWORD=purdue@ztx

apt-get -y update && apt-get -y upgrade && apt-get -y update && apt-get -y dist-upgrade

num_vcpu=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
if [ "$num_vcpu" -gt 0 ]; then
    echo 'Hardware Virtualization is supported.'
else
    echo 'Hardware Virtualization is not supported.'
    exit 1
fi

source setupPhysicalServer.sh 

# Create directory for base OS images.
sudo mkdir /var/lib/libvirt/images/purdue-ztx

qemu-img info $WORKDIR/ubuntu-22.04-purdue-ztx.qcow2

sudo cp $WORKDIR/ubuntu-22.04-purdue-ztx.qcow2 /var/lib/libvirt/images/purdue-ztx/ubuntu-22.04-purdue-ztx.qcow2

wget https://raw.githubusercontent.com/UmakantKulkarni/kvm-setup/main/createvm
chmod +x createvm
sudo mv createvm /usr/local/bin/

createvm master 101
createvm worker1 102
createvm worker2 103
createvm worker3 104
createvm worker4 105

echo "Waiting for 60 seconds..."
sleep 60
sudo virsh list --all

master_node_ip=$(sudo virsh domifaddr master | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
worker_node1_ip=$(sudo virsh domifaddr worker1 | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
worker_node2_ip=$(sudo virsh domifaddr worker2 | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
worker_node3_ip=$(sudo virsh domifaddr worker3 | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
worker_node4_ip=$(sudo virsh domifaddr worker4 | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
declare -a all_k8_node_ips=($master_node_ip $worker_node1_ip $worker_node2_ip $worker_node3_ip $worker_node4_ip)
declare -a worker_node_ips=($worker_node1_ip $worker_node2_ip $worker_node3_ip $worker_node4_ip)

for k8_node_ip in "${all_k8_node_ips[@]}"
do
    echo ""
    echo "Preparing K8s node $k8_node_ip"
    echo ""
    sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no $VM_USERNAME@$k8_node_ip "bash /opt/scripts/updateK8Nodes.sh $VM_USERNAME $VM_PASSWORD"
    echo ""
    echo "Prepared node"
    echo ""
done

echo "Waiting for 30 seconds..."
sleep 30

k8s_create_cmd="kubeadm init --pod-network-cidr=10.244.0.0/16 --token-ttl=0 --apiserver-advertise-address=$master_node_ip"
declare -a master_node_cmds=($k8s_create_cmd "export KUBECONFIG=/etc/kubernetes/admin.conf" "sleep 60" "kubectl get node -owide" "kubectl apply -f /opt/k8s/kube-flannel.yml" "kubectl apply -f /opt/k8s/metrics-server.yaml" "kubectl get pods -A")
for master_node_cmd in "${master_node_cmds[@]}"
do	
    echo ""
    echo "Executing comand - $master_node_cmd on Master node $master_node_ip"
    echo ""
    sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no $VM_USERNAME@$master_node_ip $master_node_cmd
    echo ""
    echo "Finished Executing comand"
    echo ""
done

echo "Waiting for 30 seconds..."
sleep 30

k8s_join_cmd=$(sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no $VM_USERNAME@$master_node_ip "kubeadm token create --print-join-command")

for worker_node_ip in "${worker_node_ips[@]}"
do	
    echo ""
    echo "Executing K8s join comand on Worker node $worker_node_ip"
    echo ""
    sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no $VM_USERNAME@$worker_node_ip $k8s_join_cmd
    echo ""
    echo "Finished Executing comand"
    echo ""
done

echo "Waiting for 60 seconds..."
sleep 60

#sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no $VM_USERNAME@$master_node_ip "bash /opt/scripts/labelK8sNodes.sh"
#sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no $VM_USERNAME@$master_node_ip "bash /opt/scripts/nukeOpen5gs.sh 0"
