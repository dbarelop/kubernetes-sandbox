# Kubernetes basic command-line operations
Kubernetes is an open-source platform for automating deployment, scaling, and operations of application containers across clusters of hosts.
## Initializing the master and slave nodes
This command initializes the Kubernetes master controller: 
```
$ sudo kubeadm init
```
Upon completion, the program will return the command that has to be issued in the slave machines, in the form of `kubeadm join --token <token> <master-ip>` (the command needs to be run with `sudo`).
NOTE: It's possible that `kubeadm` complains about the directory `/var/lib/kubelet` not being empty. In that case, `kubeadm` needs to be run with the flag `--skip-preflight-checks` (right after the commands `init` or `join`)
## Installing a pod network
It is necessary to install a pod network add-on for pods to be able to communicate with each other when they are on different hosts.
This needs to be done **before** deploying any application to the cluster.
There are [several projects](http://kubernetes.io/docs/admin/addons/) that provide Kubernetes pod networks. [Weave Net](https://github.com/weaveworks/weave-kube) is one of them. It can be installed on the master node with the following command:
```
$ kubectl apply -f https://git.io/weave-kube
```
Once a pod network has been installed, you can confirm that it is working by checking that the `kube-dns` pod is `Running` in the output of `kubectl get pods --all-namespaces`. This signifies the cluster is ready.
## Installing a sample application
To install the demo application *[Sock Shop](https://github.com/microservices-demo/microservices-demo)*, the following steps have to be followed:

1. Create the namespace where the application will run:
`$ sudo kubectl create namespace sock-shop`

2. Apply the configuration from the yml file in the repository:
`$ sudo kubectl apply -n sock-shop -f "https://github.com/microservices-demo/microservices-demo/blob/master/deploy/kubernetes/complete-demo.yaml?raw=true"`

3. Wait until the components are downloaded and all the containers start. The command `kubectl get pods -n sock-shop` can be used to see which ones are up and running.

4. Access the application with the URL `http://<master_ip>:<port>`. The port can be found in the output of the command `kubectl describe svc front-end -n sock-shop` in the `NodePort` section.

## References
* [Kubernetes documentation](http://kubernetes.io/docs/)
* [Kubernetes guide on installing Kubernetes on Linux](http://kubernetes.io/docs/getting-started-guides/kubeadm/)
