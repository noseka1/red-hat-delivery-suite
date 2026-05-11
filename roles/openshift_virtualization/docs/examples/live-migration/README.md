# Virtual machine live-migration

The storageclasses used in the example manifest will likely not match the
storageclass available on your cluster. Use the grep command to find the
storageclass occurences and update them to match your cluster:

```
$ grep -r storageClassName *
```

Create source namespace:

```
$ oc apply -f virtualmachine/namespace.yaml
```

Create an example virtual machine that will be live-migrated:

```
$ oc apply -R -f virtualmachine
```

## Live-migration

Live-migrate the VM to a different cluster node:

```
$ oc apply -f live-migration/anynode-vmim.yaml
```

Example situation after running the command:

```
$ oc get po -n kubevirt-migrate-source -o wide
NAME                          READY   STATUS      RESTARTS   AGE   IP            NODE      NOMINATED NODE   READINESS GATES
virt-launcher-example-l7xcb   0/2     Completed   0          81m   10.130.0.26   worker2   <none>           1/1
virt-launcher-example-llc8g   2/2     Running     0          93s   10.129.0.6    worker1   <none>           1/1
```

The same migration can be accomplished using:

```
$ virtctl migrate example
```

Live-migrate the VM to a specific cluster node. Update the `nodeselector-vmim.yaml` by editing the node selector to choose the
target node:

```
$ vi live-migration/nodeselector-vmim.yaml
```

Live-migrate the VM to the specific node:

```
oc apply -f live-migration/nodeselector-vmim.yaml
```

Example situation after running the command:

```
$ oc get po -n kubevirt-migrate-source -o wide
NAME                          READY   STATUS      RESTARTS   AGE     IP            NODE      NOMINATED NODE   READINESS GATES
virt-launcher-example-hhbl7   2/2     Running     0          23s     10.128.0.26   master1   <none>           1/1
virt-launcher-example-llc8g   1/2     Completed   0          3m28s   10.129.0.6    worker1   <none>           1/1
```

The same migration can be accomplished using:

```
$ virtctl migrate --addedNodeSelector kubernetes.io/hostname=master1 example
```

## Volume migration (aka storageclass migration)

To convert volumes from one storageclass to another, issue:

```
$ oc apply -R -f volume-migration
```

Example situation after running the command:

```
$ oc get po -n kubevirt-migrate-source -o wide
NAME                          READY   STATUS      RESTARTS   AGE     IP            NODE      NOMINATED NODE   READINESS GATES
virt-launcher-example-hhbl7   0/2     Completed   0          38m     10.128.0.26   master1   <none>           1/1
virt-launcher-example-z9ft9   2/2     Running     0          6m54s   10.129.0.9    worker1   <none>           1/1
```

```
$ oc get pvc -n kubevirt-migrate-source
NAME                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     VOLUMEATTRIBUTESCLASS   AGE
example-rootdisk          Bound    pvc-9f30e704-1a12-44d6-91e0-cc6269595f78   10Gi       RWX            nfs-csi          <unset>                 3h9m
example-rootdisk-target   Bound    pvc-c1bd7968-2dd0-4426-b0a8-a160d396c68b   10Gi       RWX            local-hostpath   <unset>                 11m
```

## Decentralized live migration

Decentralized live migration is a storage live migration that allows you to migrate virtual machines between namespaces or even between different OpenShift clusters.

Decentralized live migration is available in OpenShift *4.20 or later*.

To enable the decentralized live migration, you must set a feature gate in OpenShift Virtualization. If you are live-migrating between clusters, both clusters (source and target) must have this feature gate enabled:

```
$ oc patch hyperconverged -n openshift-cnv kubevirt-hyperconverged --type json -p '[{"op":"replace", "path": "/spec/featureGates/decentralizedLiveMigration", "value": true}]'
```

The cross cluster live-migration is orchestrated using MTV. You can find the respective documenation at:
* [Live migration in MTV](https://docs.redhat.com/en/documentation/migration_toolkit_for_virtualization/2.11/html-single/planning_your_migration_to_red_hat_openshift_virtualization/index#assembly_live-migration_mtv)
* [OpenShift Virtualization live migration prerequisites](https://docs.redhat.com/en/documentation/migration_toolkit_for_virtualization/2.11/html-single/planning_your_migration_to_red_hat_openshift_virtualization/index#cnv-cnv-live-prerequisites_mtv)

In the source cluster, install MTV version *2.10.0 or later*. As per instructions in [About Migration Toolkit for Virtualization (MTV) providers](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/virtualization/live-migration#virt-about-mtv-providers), configure OpenShift Virtualization provider for the target cluster. Note that the openshift_virtualization Ansible role creates the service account required for live-migrations on the target cluster. You can obtain the respective service account token by running this command against the target cluster:

```
$ oc extract -n kube-system secret/mtv-live-migration --keys token --to -
```

Using the token obtained from the output of the above command you can go to OpenShift Web Console of the source cluser and create the OpenShift Virtualization provider. In the OpenShift Web Console, navigate to Migration for Virtualization -> Providers and click on the "Create provider" button. Alternatively, you can leverage the example manifests located in the [mtv-provider directory](mtv-provider).

Both the source and target clusters must be connected to the migration network. This network facilitates IP connectivity for the virt-handler and virt-synchronization-controller pods between the two clusters. You can find example network attachment definitions for the migration networks in the [migration-network directory](migration-network). Note that clusters can be connected to different migration networks. If so then there must be an IP route between the two networks. Refer to [Configuring a cross-cluster live migration network](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/virtualization/live-migration#virt-configuring-cross-cluster-live-migration-network) and [Configuring KubeVirt CA with cross cluster live migration](https://kubevirt.io/user-guide/compute/decentralized_live_migration/#configuring-kubevirt-ca-with-cross-cluster-live-migration).

After creating the migration network using the net-attach-def resource, you can configure OpenShift Virtualization to use this network for live migrations. Replace the migration network name with your network name before issuing this command:

```
$ oc patch hyperconverged -n openshift-cnv kubevirt-hyperconverged --type json -p '[{"op":"replace", "path": "/spec/liveMigrationConfig/network", "value": "default/vm-migration"}]'
```

Create and configure the migration network on the target cluster as well.

In the target cluster, create the namespace for VM to be migrated into:

```
$ oc apply -f decentralized-live-migration/target/namespace.yaml
```

In the source cluster, prepare the migration plan:

```
$ oc apply -R -f decentralized-live-migration/source/plan
```

Trigger the decentralized live migration to move a VM from the source to the target cluster:

```
$ oc apply -f decentralized-live-migration/source/migrate/migration.yaml
```

After the VM is migrated, it will be stopped on the source cluster:

```
oc get vm -n kubevirt-migrate-source
NAME      AGE   STATUS    READY
example   10d   Stopped   False
```

You will find the VM running on the target cluster:

```
$ oc get vm -n kubevirt-migrate-tar
get
NAME      AGE     STATUS    READY
example   6m15s   Running   True
```

## References

* [Live Migration](https://kubevirt.io/user-guide/compute/live_migration/)
* [Volume migration](https://kubevirt.io/user-guide/storage/volume_migration/)
* [Decentralized live migration](https://kubevirt.io/user-guide/compute/decentralized_live_migration/#decentralized-live-migration)
