#!/bin/bash

HOST_CLUSTER_CONTEXT="clusterz5"

# Install Kubefed
wget -O - https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/kubernetes-client-linux-amd64.tar.gz \
    | tar xzvf - kubernetes/client/bin/kubefed --strip-components=3 && sudo mv kubefed /usr/bin

# Install Helm package manager
wget https://kubernetes-helm.storage.googleapis.com/helm-v2.4.1-linux-amd64.tar.gz -O - \
    | tar xzvf - linux-amd64/helm --strip-components=1 && sudo mv helm /usr/bin
helm init

# Setup RBAC
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
kubectl -n kube-system patch deploy/tiller-deploy -p '{"spec": {"template": {"spec": {"serviceAccountName": "tiller"}}}}'

# Deploy CoreDNS
cat << 'EOF' > coredns-chart.yaml
isClusterService: false
serviceType: "NodePort"
middleware:
  kubernetes:
    enabled: false
  etcd:
    enabled: true
    zones:
    - "fed.io"
    endpoint: "http://etcd-cluster.ns:2379"
EOF
helm install --namespace kube-system --name coredns -f coredns-chart.yaml stable/coredns

# Bring up the Federation Control Plane
cat << 'EOF' > federation-dns-provider.conf
[Global]
etcd-endpoints = http://etcd-cluster.ns:2379
zones = fed.io.
EOF
kubefed init federation --host-cluster-context=$HOST_CLUSTER_CONTEXT \
                        --api-server-service-type=NodePort \
                        --etcd-persistent-storage=false \
                        --dns-provider=coredns \
                        --dns-provider-config=federation-dns-provider.conf \
                        --dns-zone-name=fed \
                        --controllermanager-arg-overrides='--v=6' --v=6

# Join the Federation
kubefed join $HOST_CLUSTER_CONTEXT --host-cluster-context=$HOST_CLUSTER_CONTEXT --context=federation

