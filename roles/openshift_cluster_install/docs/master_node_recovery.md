# Restoring 1 of the 3 master nodes in an agent-based cluster

This tutorial was validated using a compact OCP 4.21.23 cluster, which was deployed through the agent-based installation method.

```
$ oc get bmh -n openshift-machine-api
```

```
NAME           STATE                    CONSUMER                    ONLINE   ERROR   AGE
m1mycluster9   externally provisioned   mycluster9-hk2rm-master-0   true             19h
m2mycluster9   externally provisioned   mycluster9-hk2rm-master-1   true             19h
m3mycluster9   externally provisioned   mycluster9-hk2rm-master-2   true             19h
```
Remove the **metal3.io/autoscale-to-hosts** annotation from the worker MachineSet if it is there. This annotation interferes with the reprovisioning of the master node. We will restore this annotation after the master node is provisioned:

```
$ oc annotate machineset -n openshift-machine-api mycluster9-hk2rm-worker-0 metal3.io/autoscale-to-hosts-
```

Back up the resources that define the master node that you are replacing. In this example, we are replacing the master node **m3mycluster9**. We will back up the respective Machine, BareMetalHost, and the Secret objects referenced by the BareMetalHost. Note that in our case, there was no network-config-secret to back up:

```
$ oc get machine -n openshift-machine-api mycluster9-hk2rm-master-2 -o yaml > mycluster9-hk2rm-master-2-machine.yaml
```

```
$ oc get bmh -n openshift-machine-api m3mycluster9 -o yaml > m3mycluster9-bmh.yaml
```

```
$ oc get secret -n openshift-machine-api m3mycluster9-bmc-secret -o yaml > m3mycluster9-bmc-secret-secret.yaml
```

Next, delete the resources of the "failed" master node from the cluster. Note that this will remove the master node from the cluster:

```
$ oc delete machine -n openshift-machine-api mycluster9-hk2rm-master-2
```

```
$ oc delete bmh -n openshift-machine-api m3mycluster9
```

Force the BareMetalHost object deletion by removing the finalizer if needed.

Delete the Node object (**m3mycluster9** in our case) if still present. The Node object should no longer appear in the list of nodes:

```
$ oc get node
```

```
NAME           STATUS   ROLES                         AGE   VERSION
m1mycluster9   Ready    control-plane,master,worker   20h   v1.34.8
m2mycluster9   Ready    control-plane,master,worker   20h   v1.34.8
```

You may need to recreate the node provisioning secrets (BMC and network-config-secret) if they were deleted while deleting the BareMetalHost object.

Create a cleaned-up version of the bare metal resources and apply them to the cluster to reprovision the master nodes. Make sure that the **baremetalhost.spec.customDeploy** element was removed from the yaml or the provisioning will start immediately which is not desired. Instead, the provisioning should be triggered when the Machine object is created.

Example of cleaned-up resources:

```
$ cat m3mycluster9-bmh.yaml
```

```
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: m3mycluster9
  namespace: openshift-machine-api
spec:
  automatedCleaningMode: disabled
  bmc:
    address: redfish-virtualmedia+https://sushy.lab.example.com:8000/redfish/v1/Systems/00000000-0000-0009-0023-000000000000
    credentialsName: m3mycluster9-bmc-secret
    disableCertificateVerification: true
  bootMACAddress: "52:54:00:09:23:00"
  bootMode: legacy
  online: true
  rootDeviceHints:
    deviceName: /dev/vda
```

```
$ cat mycluster9-hk2rm-master-2-machine.yaml
```

```
apiVersion: machine.openshift.io/v1beta1
kind: Machine
metadata:
  annotations:
    metal3.io/BareMetalHost: openshift-machine-api/m3mycluster9
  labels:
    machine.openshift.io/cluster-api-cluster: mycluster9-hk2rm
    machine.openshift.io/cluster-api-machine-role: master
    machine.openshift.io/cluster-api-machine-type: master
  name: mycluster9-hk2rm-master-2
  namespace: openshift-machine-api
spec:
  metadata: {}
  providerSpec:
    value:
      apiVersion: baremetal.cluster.k8s.io/v1alpha1
      customDeploy:
        method: install_coreos
      hostSelector: {}
      image:
        checksum: ""
        url: ""
      kind: BareMetalMachineProviderSpec
      metadata: {}
      userData:
        name: master-user-data-managed
```

The replacement master node starts provisioning several minutes after applying the bare metal resources to the cluster:

```
$ oc get bmh -n openshift-machine-api
```

```
NAME           STATE                    CONSUMER                    ONLINE   ERROR   AGE
m1mycluster9   externally provisioned   mycluster9-hk2rm-master-0   true             21h
m2mycluster9   externally provisioned   mycluster9-hk2rm-master-1   true             21h
m3mycluster9   inspecting               mycluster9-hk2rm-master-2   true             4m43s
```

The restored master node is no longer `externally provisioned` but `provisioned`:

```
$ oc get bmh -A
```

```
NAME           STATE                    CONSUMER                    ONLINE   ERROR   AGE
m1mycluster9   externally provisioned   mycluster9-hk2rm-master-0   true             21h
m2mycluster9   externally provisioned   mycluster9-hk2rm-master-1   true             21h
m3mycluster9   provisioned              mycluster9-hk2rm-master-2   true             63m
```

Restore the **metal3.io/autoscale-to-hosts** annotation on the worker MachineSet if it was originally present:

```
$ oc annotate machineset -n openshift-machine-api mycluster9-hk2rm-worker-0 metal3.io/autoscale-to-hosts=""
```
