#!/bin/bash

num_vms=$1

# https://bash.cyberciti.biz/virtualization/shell-script-to-setup-an-lxd-linux-containers-vm-lab-for-testing-purpose/
token="012345.0123456789abcdef"
master_ip="10.114.13.1"
vm_bridge="lxdbr0"
vm_net_if="eth0"
vm_subnet="10.114.13"
vm_first_ip="3"

sudo add-apt-repository ppa:ubuntu-lxc/lxd-git-master
sudo apt-get update
sudo apt-get install -y lxd

# Initialize LXD and the bridge interface
# TODO: add parameters for batch execution
sudo lxd init
sudo systemctl start lxd

# Increase kernel limits to run Kubernetes on LXD
sudo sysctl fs.inotify.max_user_instances=1048576  
sudo sysctl fs.inotify.max_queued_events=1048576  
sudo sysctl fs.inotify.max_user_watches=1048576  
sudo sysctl vm.max_map_count=262144

# Start Kubernetes master
sudo kubeadm init --token $token --apiserver-advertise-address $master_ip

for i in $(seq 1 $num_vms); do
    # Create VM
    lxc init ubuntu:16.04 u$i -c security.privileged=true -c security.nesting=true -c linux.kernel_modules=ip_tables,ip6_tables,netlink_diag,nf_nat,overlay -c raw.lxc=lxc.aa_profile=unconfined
    lxc config device add u$i mem unix-char path=/dev/mem
    # Config networking for VM
    lxc network attach $vm_bridge u$i $vm_net_if
    lxc config device set u$i $vm_net_if ipv4.address $vm_subnet.$vm_first_ip
    # Start VM
    lxc start u$i

    lxc exec u$i -- apt-get update
    lxc exec u$i -- apt-get install -y apt-transport-https
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | lxc exec u$i -- apt-key add -
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | lxc exec u$i -- tee /etc/apt/sources.list.d/kubernetes.list
    lxc exec u$i -- apt-get update
    lxc exec u$i -- apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni aufs-tools
    # ERROR: failed to parse kernel config: unable to load kernel module "configs"
    lxc exec u$i -- kubeadm join --token $token $master_ip:6443

    (( vm_first_ip++ ))
done
