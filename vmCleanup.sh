#!/usr/bin/env bash

sudo virsh shutdown master
sudo virsh shutdown worker1
sudo virsh shutdown worker2
sudo virsh shutdown worker3
sudo virsh shutdown worker4
sudo virsh shutdown worker5
sudo virsh shutdown ran

echo "Waiting for 30 seconds for VMs to shut down..."
sleep 30

sudo virsh undefine master
sudo virsh undefine worker1
sudo virsh undefine worker2
sudo virsh undefine worker3
sudo virsh undefine worker4
sudo virsh undefine worker5
sudo virsh undefine ran

rm -rf /var/lib/libvirt/images/*
