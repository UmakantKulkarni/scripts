#!/usr/bin/env bash

DEBIAN_FRONTEND=noninteractive

my_dir=/tmp

cd $my_dir

DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade

DEBIAN_FRONTEND=noninteractive apt -y install python3-pip python3-setuptools python3-wheel ninja-build build-essential flex bison git libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libmicrohttpd-dev libcurl4-gnutls-dev meson iproute2 libnghttp2-dev vim iptables cmake gnupg libtins-dev gdb tzdata ntp ntpstat ntpdate libtalloc-dev apache2-utils default-jre default-jdk wget nano make g++ lksctp-tools net-tools tcpdump curl jq iputils-ping nghttp2-client bash-completion xauth gcc autoconf libtool pkg-config libmnl-dev libyaml-dev sshpass x11-apps feh tshark openssh-client openssh-server systemd systemd-sysv dbus dbus-user-session bridge-utils libvirt-clients libvirt-daemon-system qemu-system-x86 kpartx extlinux cryptsetup qemu-kvm virtinst libvirt-daemon-system cloud-image-utils cloud-guest-utils libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libzmq3-dev libgtest-dev libyaml-cpp-dev software-properties-common libnetfilter-queue-dev traceroute

pip3 install -U h2

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
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
apt-get -y update
apt-get install -y ca-certificates
apt-get install -y apt-transport-https
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get -y update
apt-get install -y kubectl kubelet kubeadm

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get -y update
apt-get install -y helm

systemctl restart kubelet
systemctl enable kubelet

cd /opt
git clone -b benchmark https://github.com/UmakantKulkarni/opensource-5g-core
cd /opt/opensource-5g-core && git pull

cd /opt
git clone -b oai https://github.com/UmakantKulkarni/scripts
cd /opt/scripts && git pull

#https://istio.io/latest/docs/setup/getting-started/#download
cd /opt
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.1 TARGET_ARCH=x86_64 sh -
cd istio-1.22.1
echo "export PATH=$PWD/bin:$PATH" >> ~/.bashrc
export PATH=$PWD/bin:$PATH

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
echo "export PCS_SETUP_TUN_INTF=false" >> ~/.bashrc
source ~/.bashrc

#echo "Downloading Ubuntu Purdue ZTX QCOW Image into /tmp directory - https://www.cs.purdue.edu/homes/ukulkarn/ubuntu-22.04-purdue-ztx.qcow2"

#cd $my_dir
#rm -f ubuntu-22.04-purdue-ztx.qcow2
#wget https://www.cs.purdue.edu/homes/ukulkarn/ubuntu-22.04-purdue-ztx.qcow2

