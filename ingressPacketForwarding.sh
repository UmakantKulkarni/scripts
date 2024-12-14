#!/usr/bin/env bash

#https://blog.gordonbuchan.com/blog/index.php/2021/04/05/forwarding-ports-to-a-kvm-guest-using-iptables-and-network-address-translation-nat/

# Enable IP firwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1
# To make it permanent, edit /etc/sysctl.conf

# values
kvmsubnet="192.168.122.0/24"
wanadaptername="enp3s0f0np0"
wanadapterip="10.10.1.1"
kvmadaptername="virbr0"
kvmworkerip="192.168.122.188"
 
iptables -I FORWARD -i $wanadaptername -o $kvmadaptername -d $kvmsubnet -j ACCEPT
iptables -I FORWARD -i $kvmworkerip -o $wanadaptername -s $kvmsubnet -j ACCEPT
iptables -t nat -A PREROUTING -i $wanadaptername -d $wanadapterip -p sctp --dport 30412 -j  DNAT --to-destination $kvmworkerip:30412
