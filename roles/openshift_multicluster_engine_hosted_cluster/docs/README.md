# Deploying hosted clusters

## Publishing strategy for APIServer

The publishing strategy for the APIServer is configured in the field `HostedCluster.spec.services.servicePublishingStrategy.type`. There are two options for publishing the APIServer endpoint: *LoadBalancer* and *NodePort*.

### Publishing APIServer endpoint using LoadBalancer service

For KubeVirt hosted cluster, the management OCP cluster must have support for LoadBalancer service. You can for example install MetalLB to get the LoadBalancer service support.

If the hosting cluster doesn't have support for service of type LoadBalancer, the hosted clusters deployment gets stuck early on:

```
$ oc get po -n mycluster20-hosted-mycluster20
```

```
NAME                                     READY   STATUS     RESTARTS   AGE
capi-provider-85bcd6cdc5-r9t5j           0/1     Init:0/1   0          33m
cluster-api-d574d6b7b-v642g              1/1     Running    0          33m
control-plane-operator-76c57b8cf-f66xw   1/1     Running    0          33m
```

Make sure that your cluster supports the service of type LoadBalancer before attempting the hosted cluster deployment.

No DNS entry is needed for the APIServer endpoint if it is published using the LoadBalancer strategy. The cluster will install correctly without any APIServer DNS record. In the generated kubeconfig file, the Kubernetes API endpoint will include the IP address of the LoadBalancer, for example https://192.168.50.12:6443. The IP address of the LoadBalancer may be hard-coded in other places of the hosted cluster configuration.

### Publishing APIServer endpoint using NodePort service

DNS entries must exist for `api.<cluster_name>.<base_domain>` and `api-int.<cluster_name>.<base_domain>` pointing to destination where the API Server can be reached. If the API Server is exposed as a service of type NodePort, then the DNS entries can be as simple as A records pointing to one of the nodes in the management cluster (i.e. the cluster running the HCP). For example, DNS entry `api.mycluster20.example.com` and `api-int.mycluster20.example.com` can point to the first master node of the hosting cluster `m1mycluster5.mycluster5.example.com` (IP address 192.168.50.21). The respective DNSMasq configuration:

```
host-record=api.mycluster20.example.com,192.168.50.21
host-record=api-int.mycluster20.example.com,192.168.50.21
```

## KubeVirt hosted cluster

References:
* [Create a Kubevirt cluster](https://hypershift-docs.netlify.app/how-to/kubevirt/create-kubevirt-cluster/).
* [Deploying hosted control planes on OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/hosted_control_planes/deploying-hosted-control-planes#deploying-hosted-control-planes-on-openshift-virtualization)

## Agent hosted cluster

References:
* [Create an Agent cluster](https://hypershift-docs.netlify.app/how-to/agent/create-agent-cluster/).
* [Deploying hosted control planes on bare metal](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/hosted_control_planes/deploying-hosted-control-planes#deploying-hosted-control-planes-on-bare-metal)

## References

* [Support matrix for hosted control planes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/hosted_control_planes/preparing-to-deploy-hosted-control-planes#hcp-support-matrix_hcp-requirements)
* [Deploying hosted control planes on AWS](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/hosted_control_planes/deploying-hosted-control-planes#deploying-hosted-control-planes-on-aws)
