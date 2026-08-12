# Planning OpenShift Cluster Upgrade

## Impact of Cluster Upgrade on Workloads

**The cluster upgrade doesn't have any impact on the workloads** (e.g virtual machines) running on the cluster. To achieve that the fully automated update procedure updates the cluster node by node:

1. Drain the node prior to the update. This live-migrates all VMs away from the node.
2. Update the node and reboot it.
3. Wait until the node rejoins the cluster and becomes healthy.
4. Proceed with updating the next cluster node.

By design, there should be no application outages during the cluster and operator upgrade.

We will be upgrading non-production clusters (Sandbox, Dev and QA) first. Any issues like VM not working correctly on newer versions should be discovered at this phase before upgrading the production clusters.

## OpenShift Upgrade Cadence

OpenShift clusters will undergo upgrades on a regular cadence. OpenShift upgrades may be linked to hardware upgrades.

We intend to utilize the [OpenShift EUS (Extended Update Support)](https://access.redhat.com/support/policy/updates/openshift-eus) releases, which offer the longest possible support windows from Red Hat.

## Deciding on Cluster Upgrade

Review the [Red Hat OpenShift Container Platform Life Cycle Policy](https://access.redhat.com/support/policy/updates/openshift) and use the [Red Hat OpenShift Container Platform Update Graph](https://access.redhat.com/labs/ocpupgradegraph/update_path) to pick a cluster version to upgrade to.

Before deciding to upgrade to a specific OCP release, review the respective OCP release notes carefully. They may include information about possible compatibility issues, deprecated and removed features, and known issues. The OCP release notes can be found in the respective OCP documentation. For example release notes for OCP 4.22 can be found in [OpenShift Container Platform 4.22 release notes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/release_notes/index#ocp-4-22-release-notes).

Before deciding to upgrade, check for the [Kubernetes API deprecations and removals](https://access.redhat.com/articles/6955985). You must evaluate your cluster for any APIs in use that will be removed and migrate the affected components to use the appropriate new API version.

> :exclamation: Note that **downgrading of OpenShift clusters is not supported** by Red Hat. If the OpenShift cluster is downgraded, Red Hat will refuse to support such a cluster. Problems associated with a particular OpenShift upgrade can be resolved by upgrading to the subsequent release.

Before deciding to upgrade, make sure that all the OLM-managed operators will be compatible with the newer version of OCP. For some operators, a version that is compatible with the target OCP version may not be available yet. Red Hat will release a new version of the operator that will support the given OCP version eventually.

> :exclamation: If a specific operator is not currently available for the intended OCP release, refrain from upgrading OpenShift; otherwise, you will be unable to utilize the operator.

You can use the [Red Hat OpenShift Container Platform Operator Update Information Checker](https://access.redhat.com/labs/ocpouic) to verify the availability of the operators for the given target OCP version. The operator support periods are also documented in [OpenShift Operator Life Cycles](https://access.redhat.com/support/policy/updates/openshift_operators).

# Upgrading OpenShift Cluster

## Reviewing Cluster Upgrade Documentation

Before upgrading the cluster, read through the related documentation:

* Review the OCP release notes and upgrade instructions.
* Review release notes and upgrade instructions for OLM-managed operators.

Check if there is an article specific for your target OCP version in the Red Hat knowledge base, for example [Preparing to upgrade to OpenShift Container Platform 4.20](https://access.redhat.com/articles/7130599). You can use the search box to search for an article for your specific OpenShift version. Follow the instructions in the article.

## Creating proactive Red Hat Support Case

If you are upgrading a production cluster, open a [PROACTIVE support case](https://access.redhat.com/solutions/3521621) and upload a must-gather to this support case. You can collect the must-gather by logging into the cluster and issuing the following command:

```
$ oc adm must-gather
```

Create a tarball to upload:

```
$ tar cJfv must-gather.tar.xz ./must-gather-dir
```

## Cluster Upgrade Pre-Flight Checks

There are several checks you can perform to verify that the cluster is ready for upgrade.

### Check MachineConfigPools

Verify the MachineConfigPools using the command:

```
$ oc get machineconfigpools.machineconfiguration.openshift.io
```

There should be no update in progress (*Updated=True*, *Updating=False*) and the MachineConfigPools should be healthy (*Degraded=False*):

```
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
master   rendered-master-6969fd5a64d53f88a83acd68a0d0eb75   True      False      False      1              1                   1                     0                      67d
worker   rendered-worker-d7d56e357cd9af7d3a706c7e4304d233   True      False      False      2              2                   2                     0                      67d
```

In OpenShift 4.19 and above, you can view the MachineConfigNode status:

```
$ oc get machineconfignodes.machineconfiguration.openshift.io
```

```
NAME           POOLNAME   DESIREDCONFIG                                      CURRENTCONFIG                                      UPDATED   AGE
m1mycluster3   master     rendered-master-6969fd5a64d53f88a83acd68a0d0eb75   rendered-master-6969fd5a64d53f88a83acd68a0d0eb75   True      67d
w1mycluster3   worker     rendered-worker-d7d56e357cd9af7d3a706c7e4304d233   rendered-worker-d7d56e357cd9af7d3a706c7e4304d233   True      63d
w2mycluster3   worker     rendered-worker-d7d56e357cd9af7d3a706c7e4304d233   rendered-worker-d7d56e357cd9af7d3a706c7e4304d233   True      50d
```

The output should show that all nodes are up to date, i.e. the *UPDATED* column is *True*.

### Check Health of Cluster Nodes

Verify that the cluster nodes are healthy using the command:

```
$ oc get nodes
```

```
NAME           STATUS   ROLES                         AGE   VERSION
m1mycluster3   Ready    control-plane,master,worker   67d   v1.34.8
w1mycluster3   Ready    worker                        63d   v1.34.8
w2mycluster3   Ready    worker                        50d   v1.34.8
```

The output should show that all nodes are *Ready* in the *STATUS* column.

### Check Status of Cluster Operators

Verify that all the cluster operators are available, not progressing, and not degraded:

```
$ oc get clusteroperators.config.openshift.io
```

```
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
authentication                             4.21.23   True        False         False      8h
baremetal                                  4.21.23   True        False         False      67d
cloud-controller-manager                   4.21.23   True        False         False      67d
cloud-credential                           4.21.23   True        False         False      67d
cluster-autoscaler                         4.21.23   True        False         False      67d
config-operator                            4.21.23   True        False         False      67d
console                                    4.21.23   True        False         False      27d
control-plane-machine-set                  4.21.23   True        False         False      67d
csi-snapshot-controller                    4.21.23   True        False         False      9d
dns                                        4.21.23   True        False         False      7h43m
etcd                                       4.21.23   True        False         False      67d
image-registry                             4.21.23   True        False         False      9d
ingress                                    4.21.23   True        False         False      67d
insights                                   4.21.23   True        False         False      9d
kube-apiserver                             4.21.23   True        False         False      67d
kube-controller-manager                    4.21.23   True        False         False      67d
kube-scheduler                             4.21.23   True        False         False      67d
kube-storage-version-migrator              4.21.23   True        False         False      31h
machine-api                                4.21.23   True        False         False      67d
machine-approver                           4.21.23   True        False         False      67d
machine-config                             4.21.23   True        False         False      67d
marketplace                                4.21.23   True        False         False      67d
monitoring                                 4.21.23   True        False         False      9d
network                                    4.21.23   True        False         False      67d
node-tuning                                4.21.23   True        False         False      9d
olm                                        4.21.23   True        False         False      8d
openshift-apiserver                        4.21.23   True        False         False      7d16h
openshift-controller-manager               4.21.23   True        False         False      5d7h
openshift-samples                          4.21.23   True        False         False      67d
operator-lifecycle-manager                 4.21.23   True        False         False      67d
operator-lifecycle-manager-catalog         4.21.23   True        False         False      67d
operator-lifecycle-manager-packageserver   4.21.23   True        False         False      7h43m
service-ca                                 4.21.23   True        False         False      67d
storage                                    4.21.23   True        False         False      67d
```

### Check Pods in Bad State

Issue the following command to list pods that are in a failed state:

```
$ oc get pods -A | grep -E '(CrashLoopBackOff|Error|ContainerStatusUnknown|ImagePullBackOff|Init:ContainerStatusUnknown)'
```

Ideally, the output of the above command is empty. If there are failing pods, review each of them and decide if you want to fix them prior to the cluster upgrade.
