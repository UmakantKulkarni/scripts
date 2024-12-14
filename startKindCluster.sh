#!/usr/bin/env bash

DEBIAN_FRONTEND=noninteractive
my_dir=/opt
cd $my_dir

DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade

kind_cluster_config_file="$my_dir/k8s/kind-cluster.yaml"
cat <<EOF > "$kind_cluster_config_file"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF

kind delete cluster
kind create cluster --config $kind_cluster_config_file
sleep 10
kubectl taint nodes $(kubectl get nodes --selector=node-role.kubernetes.io/control-plane | awk 'FNR==2{print $1}') node-role.kubernetes.io/control-plane-
kubectl create -f $my_dir/k8s/metrics-server.yaml
bash $my_dir/scripts/labelK8sNodes.sh
kubectl taint nodes $(kubectl get nodes --selector=node-role.kubernetes.io/control-plane | awk 'FNR==2{print $1}') node-role.kubernetes.io/control-plane-
sleep 10
echo "Kind cluster created successfully"
