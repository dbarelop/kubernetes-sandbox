# Setting up monitoring for Kubernetes

Once the Kubernetes cluster is created, its nodes will be monitored using Heapster with an InfluxDB backend and a Grafana UI.

## Starting all the pods and services

Checkout Heapster repository:

```sh
$ git clone https://github.com/kubernetes/heapster
$ cd heapster
```

Modify the Grafana deployment file to replace the environment variable `GF_SERVER_ROOT_URL`, in order to make use of the API server proxy:

```sh
$ sed -i -r 's/(value: \/)$/#\1/' deploy/kube-config/influxdb/grafana-deployment.yaml
$ sed -i -r 's/# (value: \/api\/v1\/proxy\/namespaces\/kube-system\/services\/monitoring-grafana\/)$/\1/' deploy/kube-config/influxdb/grafana-deployment.yaml
```

Deploy the pods:

```sh
$ kubectl create -f deploy/kube-config/influxdb/
```

This will start Grafana, InfluxDB and Heapster. Useful information about where each service is running can be found using `kubectl cluster-info`.

By default, InfluxDB runs on [http://monitoring-influxdb:8086](http://monitoring-influxdb:8086) and contains the database k8s (credentials root:root).

**NOTE:** Sometimes the pods fail to start and `kubectl get pods --all-namespaces` shows that *weave-net* pods are stuck in *Error* or *CrashLoopBackOff* status. `kubectl logs weave-net-* -c weave --namespace=kube-system` reveals the problem is that two nodes have the same MAC address for the *weave* interface.

A temporary solution for now is to remove the conflicting nodes from the cluster (bug [https://github.com/weaveworks/weave/issues/2427](https://github.com/weaveworks/weave/issues/2427)), change manually the MAC address with `sudo ifconfig weave hw $mac` (however, this changes aren't permanent and the assigned MAC conflicts again if the machine is rebooted).

## References

* [Heapster documentation](https://github.com/kubernetes/heapster/blob/master/docs/influxdb.md)
