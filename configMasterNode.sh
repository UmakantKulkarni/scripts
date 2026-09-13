#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
    echo 'Expected 1 CLI arguments - Interface name'
    exit 1
fi

intf="$1"
ip=$(ip addr show $intf | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")

kubeadm init --pod-network-cidr=10.244.0.0/16 --token-ttl=0 --apiserver-advertise-address=$ip --control-plane-endpoint=$ip
sleep 60
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f /opt/k8s/calico.yaml
sleep 60
kubectl --kubeconfig=/etc/kubernetes/admin.conf get node -owide
systemctl restart containerd
sleep 10
kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -A
kjoincmd=$(kubeadm token create --print-join-command)
