#!/bin/bash

# Install Vagrant, Qemu, KVM and Vagrant KMV plugin
wget https://releases.hashicorp.com/vagrant/1.9.4/vagrant_1.9.4_x86_64.deb
sudo dpkg -i vagrant_1.9.4_x86_64.deb
sudo sed -i -r 's/# deb-src/deb-src/' /etc/apt/sources.list
sudo apt-get update
sudo apt-get build-dep vagrant ruby-libvirt
sudo apt-get install qemu libvirt-bin ebtables dnsmasq
sudo apt-get install libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev
vagrant plugin install vagrant-libvirt

mkdir vagrant && cd vagrant

# Start Kubernetes master
sudo kubeadm init --apiserver-advertise-address 192.168.122.1

# Setup VM deploy script
cat << 'EOF' > deploy.sh
#!/bin/bash

for i in $(seq $1 $2); do
    if [ ! -d "u$i" ]; then
        mkdir u$i
        cat Vagrantfile | sed "s/%%hostname%%/u$i/" > u$i/Vagrantfile
        cd u$i
        vagrant up &
        cd ..
    fi
done
EOF

# Setup Vagrantfile
cat << 'EOF' > Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "nrclark/xenial64-minimal-libvirt"

  config.vm.hostname = "%%hostname%%"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  config.vm.network "public_network", bridge: "br0", dev: "br0"

  #config.vm.synced_folder "./data", "/vagrant_data"

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y apt-transport-https curl
    sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni aufs-tools
    sudo kubeadm join --token 01c85a.4b0c1da20788e3fd 192.168.122.1:6443
  SHELL
end
EOF
