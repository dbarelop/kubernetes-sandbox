#!/bin/bash

# Install Vagrant, Qemu, KVM and Vagrant KVM plugin
wget https://releases.hashicorp.com/vagrant/1.9.5/vagrant_1.9.5_x86_64.deb
sudo dpkg -i vagrant_1.9.5_x86_64.deb
sudo sed -i -r 's/# deb-src/deb-src/' /etc/apt/sources.list
sudo apt-get update
sudo apt-get build-dep -y vagrant ruby-libvirt
sudo apt-get install -y qemu libvirt-bin ebtables dnsmasq
sudo apt-get install -y libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev
sudo usermod -a -G libvirtd $(id -un)
vagrant plugin install vagrant-libvirt

# Install Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni

# Deploy Kubernetes master
vagrantaddr=$(ifconfig virbr0 | grep 'inet' | sed -r 's/ addr//' | sed -r 's/^.*inet:([^ ]+) .+$/\1/')
kube_token="012345.0123456789abcdef"
sudo kubeadm init --token $kube_token --apiserver-advertise-address $vagrantaddr
mkdir ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -un):$(id -gn) ~/.kube/config
kubectl apply -f https://github.com/weaveworks/weave/releases/download/latest_release/weave-daemonset-k8s-1.6.yaml

mkdir vagrant && cd vagrant

# Setup VM deploy script
cat << EOF > deploy.sh
#!/bin/bash
test \$# -eq 2 || printf "Usage: \$0 <first_vm> <last_vm>\nCreates u<first_vm>..u<last_vm> virtual machines\n\n"
for i in \$(seq \$1 \$2); do
    hostname="u\$i"
    if [ ! -d "\$hostname" ]; then
        mkdir \$hostname
        cat Vagrantfile | sed "s/%%hostname%%/\$hostname/" | sed "s/%%kube_token%%/$kube_token/" | sed "s/%%vagrantaddr%%/$vagrantaddr/" > \$hostname/Vagrantfile
        cd \$hostname
        vagrant up &
        cd ..
    fi
done
EOF
chmod +x deploy.sh

# Setup Vagrantfile
cat << 'EOF' > Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "nrclark/xenial64-minimal-libvirt"
  config.vm.hostname = "%%hostname%%"
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y apt-transport-https curl
    sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni aufs-tools
    sudo kubeadm join --token %%kube_token%% %%vagrantaddr%%:6443
  SHELL
end
EOF

./deploy.sh 0 7
