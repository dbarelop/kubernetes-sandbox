#!/bin/bash

test ! -z $1 || { echo "USAGE: $0 [hostname ...]"; exit 1; }

while (( $# )); do
    hostname=$1
    shift
    ssh -t $hostname "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -"
    ssh -t $hostname "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list"
    ssh -t $hostname "sudo apt update"
    ssh -t $hostname "sudo apt install -y docker.io kubelet kubeadm kubectl kubernetes-cni"
done
