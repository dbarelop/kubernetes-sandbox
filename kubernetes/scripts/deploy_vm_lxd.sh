#!/bin/bash

num_vms=$1

# https://bash.cyberciti.biz/virtualization/shell-script-to-setup-an-lxd-linux-containers-vm-lab-for-testing-purpose/
token="kubernetes"
master_ip="10.114.13.1"
vm_bridge="lxdbr0"
vm_net_if="eth0"
vm_subnet="10.114.13"
vm_first_ip="3"

sudo apt-get update
sudo apt-get install -y lxd

# Start Kubernetes master
sudo kubeadm init --token $token --apiserver-advertise-address $master_ip

# TODO: add parameters for batch execution
sudo lxd init
for i in $(seq 1 $num_vms); do
    # Create VM
    lxc init ubuntu: u$i
    # Config networking for VM
    lxc network attach $vm_bridge u$i $vm_net_if
    lxc config device set u$i $vm_net_if ipv4.address $vm_subnet.$vm_first_ip
    # Start VM
    lxc start u$i

    lxc exec u$i apt-get update
    lxc exec u$i apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | lxc exec u$i apt-key add -
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | lxc exec u$i 'tee /etc/apt/sources.list.d/kubernetes.list'
    lxc exec u$i apt-get update
    lxc exec u$i apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni aufs-tools
    lxc exec u$i kubeadm join --token $token $master_ip:6443

    (( vm_first_ip++ ))
done
