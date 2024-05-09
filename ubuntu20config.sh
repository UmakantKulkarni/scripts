cd /opt/

apt -y update

apt -y upgrade

apt -y update

apt -y install docker.io curl apache2-utils default-jre default-jdk wget git vim nano make g++ libsctp-dev lksctp-tools net-tools iproute2 libssl-dev tcpdump curl jq iputils-ping apt-transport-https nghttp2-client bash-completion xauth gcc autoconf libtool pkg-config libmnl-dev libyaml-dev sshpass python3-pip x11-apps feh

pip3 install h2

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-1-28-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-1-28-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes-1.28.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-1-29-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-1-29-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes-1.29.list

apt -y update
apt-get install -y kubelet kubeadm kubectl

#systemctl enable docker.service
#swapoff -a

cmake_ver=3.24.3

wget https://github.com/Kitware/CMake/releases/download/v$cmake_ver/cmake-$cmake_ver.tar.gz && tar -xvzf cmake-$cmake_ver.tar.gz

cd cmake-$cmake_ver && ./bootstrap -- -DCMAKE_BUILD_TYPE:STRING=Release && make && make install

cd .. && rm -rf cmake-*

cmake --version

cd /opt/

git clone -b 384636f_v3.2.6 https://github.com/UmakantKulkarni/UERANSIM && cd UERANSIM && make

cp build/nr-* /usr/local/bin/
cd ..

curl https://baltocdn.com/helm/signing.asc | apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt -y update
apt-get install helm

cd /opt/
mkdir k8s
cd k8s
curl -sL https://run.linkerd.io/install | sh
curl https://docs.projectcalico.org/manifests/calico.yaml -O
wget https://raw.githubusercontent.com/UmakantKulkarni/myCodes/master/k8/metrics-server.yaml

cd /opt/
git clone https://github.com/UmakantKulkarni/opensource-5g-core
git clone https://github.com/UmakantKulkarni/scripts
git clone --recursive https://github.com/UmakantKulkarni/open5gs
#git clone https://github.com/UmakantKulkarni/free5gmano
#git clone https://github.com/UmakantKulkarni/free5gc
#git clone https://github.com/UmakantKulkarni/amf
#git clone https://github.com/UmakantKulkarni/upf

#cd /opt/scripts 
#chmod +x *

#cd /opt/k8s
#wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
#apt -y install ./google-chrome-stable_current_amd64.deb

if (( 0 )) ; then
    cd ~/.
    apt -y remove golang-go
    rm -rf /usr/local/go
    wget https://dl.google.com/go/go1.14.4.linux-amd64.tar.gz
    tar -C /usr/local -zxvf go1.14.4.linux-amd64.tar.gz
    rm -rf go1.14.4.linux-amd64.tar.gz
    mkdir -p ~/go/{bin,pkg,src}
    echo "export GOPATH=$HOME/go" >> ~/.bashrc
    echo "export GOROOT=/usr/local/go" >> ~/.bashrc
    echo "export GO111MODULE=auto" >> ~/.bashrc
    source ~/.bashrc
    export PATH=$PATH:$GOPATH/bin:$GOROOT/bin
    apt -y update
    go get -u github.com/sirupsen/logrus
    sysctl -w net.ipv4.ip_forward=1
    #iptables -t nat -A POSTROUTING -o eno49 -j MASQUERADE
    iptables -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1400
    systemctl stop ufw
fi

cd /opt/
modprobe -r gtp5g
git clone -b v0.2.1 https://github.com/free5gc/gtp5g.git
cd gtp5g
make
make install
