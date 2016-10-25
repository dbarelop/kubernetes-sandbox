# Kubernetes basic command-line operations
Kubernetes is an open-source platform for automating deployment, scaling, and operations of application containers across clusters of hosts.
## Initializing the master and slave nodes
This command initializes the Kubernetes master controller: 
```
# kubeadm init
```
Upon completion, the program will return the command that has to be issued in the slave machines, in the form of `kubeadm join --token <token> <master-ip>`.
## Install a pod network
It is necessary to install a pod network add-on for pods to be able to communicate with each other when they are on different hosts.
This needs to be done **before** deploying any application to the cluster.
There are [several projects](http://kubernetes.io/docs/admin/addons/) that provide Kubernetes pod networks. [Weave Net](https://github.com/weaveworks/weave-kube) is one of them. It can be installed on the master node with the following command:
```
# kubectl apply -f https://git.io/weave-kube
```
Once a pod network has been installed, you can confirm that it is working by checking that the `kube-dns` pod is `Running` in the output of `kubectl get pods --all-namespaces`. This signifies the cluster is ready.
## References
* [Kubernetes documentation](http://kubernetes.io/docs/)
