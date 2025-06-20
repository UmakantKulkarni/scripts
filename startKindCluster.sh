#!/usr/bin/env bash

cilium_enabled=0
if [[ $# -eq 1 ]] ; then
    cilium_enabled=$1
else
    cilium_enabled=0
fi

DEBIAN_FRONTEND=noninteractive
my_dir=/opt
cd $my_dir

DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade

if [[ $cilium_enabled -eq 1 ]] ; then
kind_cluster_config_file="$my_dir/k8s/kind-cilium-cluster.yaml"
cat <<EOF > "$kind_cluster_config_file"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30090 # Matches the NodePort of your service
    hostPort: 9191
  - containerPort: 30080 # Matches the NodePort of your service
    hostPort: 8181
  - containerPort: 30070 # Matches the NodePort of your service
    hostPort: 7171
- role: worker
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
EOF
else
kind_cluster_config_file="$my_dir/k8s/kind-cluster.yaml"
cat <<EOF > "$kind_cluster_config_file"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30090 # Matches the NodePort of your service
    hostPort: 9191
  - containerPort: 30080 # Matches the NodePort of your service
    hostPort: 8181
  - containerPort: 30070 # Matches the NodePort of your service
    hostPort: 7171
- role: worker
- role: worker
- role: worker
EOF
fi

kind delete cluster
kind create cluster --config $kind_cluster_config_file
sleep 10
kubectl taint nodes $(kubectl get nodes --selector=node-role.kubernetes.io/control-plane | awk 'FNR==2{print $1}') node-role.kubernetes.io/control-plane-
kubectl create -f $my_dir/k8s/metrics-server.yaml
bash $my_dir/scripts/labelK8sNodes.sh kind
kubectl taint nodes $(kubectl get nodes --selector=node-role.kubernetes.io/control-plane | awk 'FNR==2{print $1}') node-role.kubernetes.io/control-plane-
sleep 10

if [[ $cilium_enabled -eq 1 ]] ; then
    helm install cilium cilium/cilium \
    --namespace kube-system \
    --set image.pullPolicy=IfNotPresent \
    --set ipam.mode=kubernetes \
    --set encryption.enabled=true \
    --set encryption.type=wireguard \
    --set encryption.nodeEncryption=true \
    --set encryption.strictMode.enabled=true \
    --set encryption.strictMode.allowRemoteNodeIdentities=false \
    --set encryption.strictMode.cidr=10.244.0.0/16 \
    --set sctp.enabled=true

    cilium status --wait
    cilium encryption status
fi

echo "Kind cluster created successfully"

# https://docs.cilium.io/en/latest/installation/kind/
# https://docs.cilium.io/en/stable/installation/kind/
# https://github.com/cilium/cilium/blob/v1.17.0-pre.3/install/kubernetes/cilium/README.md
# https://docs.cilium.io/en/latest/security/threat-model/
# https://medium.com/@charled.breteche/kind-cluster-with-cilium-and-no-kube-proxy-c6f4d84b5a9d
