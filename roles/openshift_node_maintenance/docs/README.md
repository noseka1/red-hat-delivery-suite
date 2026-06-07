# Node Maintenance Operator

The node maintenance operator achieves the same results as the oc adm cordon and oc adm drain commands, however, the Node Maintenance Operator offers a declarative approach to switch a node to maintenance by using a custom resource. When such a resource exists (NodeMaintenance) for a node, the Operator cordons and drains the node until the resource is deleted.

For example, to put node m1mycluster8 into maintenance mode, apply the following resource:

```
apiVersion: nodemaintenance.medik8s.io/v1beta1
kind: NodeMaintenance
metadata:
  name: m1mycluster8
spec:
  nodeName: m1mycluster8
  reason: NIC replacement
```

## References

* [Node Maintenance Operator](https://docs.redhat.com/en/documentation/workload_availability_for_red_hat_openshift/25.8/html/remediation_fencing_and_maintenance/node-maintenance-operator)
