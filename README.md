# 5G

## Deploy 5G core on K8s
- On cloudlab, using sfc_profile and rs630 node, create cluster with 5 nodes

- ssh on node0
    - cd /opt/
    - git clone -b ztx_cl https://github.com/UmakantKulkarni/scripts
    - cd /opt/scripts
    - ./runNodeCmd.sh "DEBIAN_FRONTEND=noninteractive apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && - DEBIAN_FRONTEND=noninteractive apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade" 0 1 2 3 4
    - ./runNodeCmd.sh "sh /local/repository/setup-grow-rootfs.sh 0" 0 1 2 3 4

- Reboot all nodes

- on node 0:

    - cd /opt/scripts
    - ./configK8Nodes.sh $intf

    - ifconfig - get interface name of public ip = intf
    - cd /opt/scripts
    - ./startK8Cluster.sh $intf

    - Check if K8s cluster is up
    - cd /opt/scripts
    - ./nukeOpen5gs.sh 0

    - Verify if open5gs is deployed.