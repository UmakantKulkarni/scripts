# Access K8s cluster locally from your physical server:

    ## Get master node ip address
    virsh domifaddr master  --source arp

    ## cd to your work directory
    cd /opt

    ## Copy .kube directory locally (password = purdue@ztx)
    scp -r root@192.168.122.27:/etc/kubernetes/admin.conf /etc/kubernetes/admin.conf

    ## Execute kubectl command
    kubectl get pods -A

# Test the setup using srsRAN

    ## Get RAN node ip address
    virsh domifaddr ran  --source arp

    ## cd to your work directory
    cd /opt/srsRAN_Project/build/

    ## Run gNB
    ./gnb -c ./gnb.yaml
    
    ## Run srsUE
    ./srsue ue.conf
