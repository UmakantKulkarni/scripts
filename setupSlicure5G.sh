#!/usr/bin/env bash

DEBIAN_FRONTEND=noninteractive
WORKDIR=/tmp
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

VM_USERNAME=root
VM_PASSWORD=purdue@ztx

DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade

num_vcpu=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
if [ "$num_vcpu" -gt 0 ]; then
    echo 'Hardware Virtualization is supported.'
else
    echo 'Hardware Virtualization is not supported.'
    exit 1
fi

bash $SCRIPT_DIR/setupPhysicalServer.sh 
cd $WORKDIR

# Create directory for base OS images.
mkdir /var/lib/libvirt/images/purdue-ztx

qemu-img info $WORKDIR/ubuntu-22.04-purdue-ztx.qcow2

cp $WORKDIR/ubuntu-22.04-purdue-ztx.qcow2 /var/lib/libvirt/images/purdue-ztx/ubuntu-22.04-purdue-ztx.qcow2

wget https://raw.githubusercontent.com/UmakantKulkarni/kvm-setup/main/createvm
chmod +x createvm
mv createvm /usr/local/bin/

createvm master 101
createvm worker1 102
createvm worker2 103
createvm worker3 104
createvm worker4 105
createvm worker5 106
createvm ran 107

echo "Waiting for 60 seconds for VMs to boot up..."
sleep 60
timeout 5 setsid virsh list --all

master_node_ip=$(timeout 5 setsid virsh domifaddr master | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
echo "Master Node IP is $master_node_ip"
worker_node1_ip=$(timeout 5 setsid virsh domifaddr worker1 | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
echo "Worker Node 1 IP is $worker_node1_ip"
worker_node2_ip=$(timeout 5 setsid virsh domifaddr worker2 | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
echo "Worker Node 2 IP is $worker_node2_ip"
worker_node3_ip=$(timeout 5 setsid virsh domifaddr worker3 | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
echo "Worker Node 3 IP is $worker_node3_ip"
worker_node4_ip=$(timeout 5 setsid virsh domifaddr worker4 | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
echo "Worker Node 4 IP is $worker_node4_ip"
worker_node5_ip=$(timeout 5 setsid virsh domifaddr worker5 | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
echo "Worker Node 5 IP is $worker_node5_ip"
ran_node_ip=$(timeout 5 setsid virsh domifaddr ran | sed -n 3p | awk '{print $4}' | cut -d "/" -f 1)
echo "RAN Node IP is $ran_node_ip"

declare -a all_k8_node_ips=($master_node_ip $worker_node1_ip $worker_node2_ip $worker_node3_ip $worker_node4_ip $worker_node5_ip $ran_node_ip)
declare -a worker_node_ips=($worker_node1_ip $worker_node2_ip $worker_node3_ip $worker_node4_ip $worker_node5_ip)
declare -a node_hostnames=("master" "worker1" "worker2" "worker3" "worker4" "worker5" "ran")

for arr_index in "${!all_k8_node_ips[@]}"
do
    k8_node_ip="${all_k8_node_ips[$arr_index]}"
    node_hostname="${node_hostnames[$arr_index]}"
    echo ""
    echo "Preparing K8s node $k8_node_ip"
    echo ""
    sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no $VM_USERNAME@$k8_node_ip "cd /opt/scripts && git pull"
    sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no $VM_USERNAME@$k8_node_ip "bash /opt/scripts/updateK8Nodes.sh $VM_USERNAME $VM_PASSWORD $node_hostname"
    echo ""
    echo "Prepared node"
    echo ""
done

echo "Waiting for 30 seconds..."
sleep 30

k8s_create_cmd="kubeadm init --pod-network-cidr=10.244.0.0/16 --token-ttl=0 --apiserver-advertise-address=$master_node_ip"
declare -a master_node_cmds=("$k8s_create_cmd" "sleep 60" "export KUBECONFIG=/etc/kubernetes/admin.conf" "kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f /opt/k8s/calico.yaml" "sleep 60" "kubectl --kubeconfig=/etc/kubernetes/admin.conf get node -owide" "systemctl restart containerd" "sleep 10" "kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -A")
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

restart_cmd="systemctl restart containerd"

for worker_node_ip in "${worker_node_ips[@]}"
do	
    echo ""
    echo "Executing restart comand on Worker node $worker_node_ip"
    echo ""
    sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no $VM_USERNAME@$worker_node_ip $restart_cmd
    echo ""
    echo "Finished Executing comand"
    echo ""
done

echo "Waiting 60 seconds for nodes to be ready..."
sleep 60

sshpass -p "$VM_PASSWORD" scp -o StrictHostKeyChecking=no -r $VM_USERNAME@$master_node_ip:/etc/kubernetes/admin.conf /etc/kubernetes/admin.conf
source ~/.bashrc

bash $SCRIPT_DIR/labelK8sNodes.sh

NAMESPACE=open5gs
bash $SCRIPT_DIR/nukeOpen5gs.sh 0 $NAMESPACE

echo "Waiting 200 seconds for nodes to be ready..."
sleep 30
kubectl taint nodes $(kubectl get nodes --selector=node-role.kubernetes.io/control-plane | awk 'FNR==2{print $1}') node-role.kubernetes.io/control-plane-
sleep 170

kubectl taint nodes $(kubectl get nodes --selector=node-role.kubernetes.io/control-plane | awk 'FNR==2{print $1}') node-role.kubernetes.io/control-plane-

kubectl patch svc amf-open5gs-sctp -n $NAMESPACE -p "{\"spec\": {\"type\": \"LoadBalancer\", \"externalIPs\":[\"$worker_node1_ip\"]}}"

testPod=`kubectl -n $NAMESPACE get po -o json |  jq '.items[] | select(.metadata.name|contains("open5gs"))| .metadata.name' | grep "test" | sed 's/"//g'`
kubectl exec -it $testPod -n $NAMESPACE -c test -- python3 /root/scripts/addMongoSubs.py 100
