#!/usr/bin/env bash

#virt-install --connect qemu:///system --virt-type kvm --name purdue-ztx --memory 16384 --vcpus=16 --os-variant ubuntu22.04 --disk path=/var/lib/libvirt/images/purdue-ztx/ubuntu-22.04-purdue-ztx.qcow2,format=qcow2 --import --network network=default --noautoconsole --graphics none

DEBIAN_FRONTEND=noninteractive

my_dir=/opt

cd $my_dir

sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512

DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade

DEBIAN_FRONTEND=noninteractive apt -y install python3-pip python3-setuptools python3-wheel ninja-build build-essential flex bison git libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libmicrohttpd-dev libcurl4-gnutls-dev meson iproute2 libnghttp2-dev vim iptables cmake gnupg libtins-dev gdb tzdata ntp ntpstat ntpdate libtalloc-dev apache2-utils default-jre default-jdk wget nano make g++ lksctp-tools net-tools tcpdump curl jq iputils-ping nghttp2-client bash-completion xauth gcc autoconf libtool pkg-config libmnl-dev libyaml-dev sshpass x11-apps feh tshark openssh-client openssh-server systemd systemd-sysv dbus dbus-user-session bridge-utils libvirt-clients libvirt-daemon-system qemu-system-x86 kpartx extlinux cryptsetup qemu-kvm virtinst libvirt-daemon-system cloud-image-utils cloud-guest-utils libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libzmq3-dev libgtest-dev libyaml-cpp-dev software-properties-common  libnetfilter-queue-dev traceroute

#echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
#systemctl restart ssh
#systemctl enable ssh

pip3 install -U h2 pyaml flask scapy

#install go - https://github.com/HewlettPackard/PacketRusher/wiki/Installation
cd $my_dir
go_ver=1.24.4
# Warning this command will remove your existing local Go installation if you have one
wget https://go.dev/dl/go${go_ver}.linux-amd64.tar.gz && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go${go_ver}.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
source $HOME/.profile

# Add Docker's official GPG key:
rm -f /etc/apt/keyrings/docker.gpg
apt-get -y update
apt-get -y install ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get -y update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
k8s_ver=v1.33
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
apt-get -y update
apt-get install -y apt-transport-https ca-certificates curl gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/${k8s_ver}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${k8s_ver}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get -y update
apt-get install -y kubectl kubelet kubeadm
apt-mark hold kubelet kubeadm kubectl

# Install kind For AMD64 / x86_64
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

cd $my_dir
git clone -b ztx_demo_aug https://github.com/UmakantKulkarni/UERANSIM && cd UERANSIM && make
cp build/nr-* /usr/local/bin/
cd ..

#https://docs.srsran.com/projects/project/en/latest/user_manuals/source/installation.html
cd $my_dir
git clone https://github.com/srsran/srsRAN_Project.git
cd srsRAN_Project
mkdir build
cd build
cmake ../ -DENABLE_EXPORT=ON -DENABLE_ZEROMQ=ON
make -j`nproc`
make install

#https://docs.srsran.com/projects/4g/en/latest/general/source/1_installation.html
cd $my_dir
git clone https://github.com/srsRAN/srsRAN_4G.git
cd srsRAN_4G
mkdir build
cd build
cmake ../
make
make install

cd $my_dir
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get -y update
apt-get install -y helm

cd $my_dir
mkdir k8s
cd k8s
curl -sL https://run.linkerd.io/install | sh

cd $my_dir
cd k8s
#https://docs.tigera.io/calico/3.25/getting-started/kubernetes/self-managed-onprem/onpremises
wget https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml
#https://github.com/flannel-io/flannel#deploying-flannel-manually
wget https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
wget https://raw.githubusercontent.com/UmakantKulkarni/myCodes/master/k8/metrics-server.yaml

cd $my_dir
git clone -b ztx_01 https://github.com/UmakantKulkarni/Secure5G
git clone -b ztx_demo_aug https://github.com/UmakantKulkarni/opensource-5g-core
git clone -b ztx_demo_aug https://github.com/UmakantKulkarni/scripts
git clone -b v2.7.2 --recursive https://github.com/open5gs/open5gs
git clone -b ztx_01 https://github.com/UmakantKulkarni/oai-cn5g-fed
#git clone https://github.com/UmakantKulkarni/free5gmano
#git clone https://github.com/UmakantKulkarni/free5gc
#git clone https://github.com/UmakantKulkarni/amf
#git clone https://github.com/UmakantKulkarni/upf

#cd /opt/k8s
#wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
#apt -y install ./google-chrome-stable_current_amd64.deb

cd $my_dir
modprobe -r gtp5g
git clone -b v0.9.3 https://github.com/free5gc/gtp5g.git
cd gtp5g
make
make install

#install gnbsim
cd $my_dir
git clone https://github.com/UmakantKulkarni/gnbsim
cd gnbsim
go build

#Kubernetes & containerd specific config
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic

tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

# Enable kernel modules
modprobe overlay
modprobe br_netfilter

# Add some settings to sysctl
tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload sysctl
sysctl --system

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

systemctl enable docker.service
systemctl enable containerd.service
systemctl enable kubelet
swapoff -a
echo '{"exec-opts": ["native.cgroupdriver=systemd"]}' | jq . > /etc/docker/daemon.json
systemctl daemon-reload
systemctl restart docker
systemctl restart kubelet
systemctl restart containerd
rm -rf /etc/cni/net.d
kubeadm reset --force --cri-socket unix:///var/run/crio/crio.sock
kubeadm reset --force --cri-socket unix:///run/containerd/containerd.sock

#https://istio.io/latest/docs/setup/getting-started/#download
cd $my_dir
istio_ver=1.26.1
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${istio_ver} TARGET_ARCH=x86_64 sh -
cd istio-${istio_ver}
echo "export PATH=$PWD/bin:$PATH" >> ~/.bashrc
export PATH=$PWD/bin:$PATH

#https://docs.cilium.io/en/latest/installation/kind/
cd $my_dir
curl -LO https://github.com/cilium/cilium/archive/main.tar.gz
tar xzf main.tar.gz
cd cilium-main/install/kubernetes

#https://docs.cilium.io/en/stable/installation/kind/
helm repo add cilium https://helm.cilium.io/

cd $my_dir
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
cilium version --client

cd $my_dir
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc
echo "alias k='kubectl'" >> ~/.bashrc
echo "alias kp='kubectl get pods --all-namespaces'" >> ~/.bashrc
echo "alias ks='kubectl get services --all-namespaces'" >> ~/.bashrc
echo "alias kn='kubectl get nodes'" >> ~/.bashrc
echo "alias kt='kubectl top pods --containers'" >> ~/.bashrc
echo "alias wkp='watch kubectl get pods -A'" >> ~/.bashrc
echo "alias kl='kubectl logs'" >> ~/.bashrc
echo "alias ke='kubectl exec -it'" >> ~/.bashrc
echo "alias kd='kubectl delete pod'" >> ~/.bashrc
echo "alias kds='kubectl describe pod'" >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc
echo "export GOPATH=$HOME/go" >> ~/.bashrc
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
echo "export GO111MODULE=auto" >> ~/.bashrc
echo "export PCS_SETUP_TUN_INTF=false" >> ~/.bashrc
source ~/.bashrc
export PATH=$PATH:$GOPATH/bin:$GOROOT/bin
