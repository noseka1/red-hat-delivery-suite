# KubeVirt Redfish

## Prerequisites

Enable the RebootPolicy feature gate on the hosting cluster by running the following command:

```
$ oc annotate --overwrite -n openshift-cnv hyperconverged kubevirt-hyperconverged \
    kubevirt.kubevirt.io/jsonpatch='[{"op":"add","path":"/spec/configuration/developerConfiguration/featureGates/-","value":"RebootPolicy"}]'
```

Enable the declarativeHotplugVolumes feature gate on the hosting cluster by running the following command:

```
$ oc patch hyperconverged kubevirt-hyperconverged -n openshift-cnv \
    --type merge \
    -p '{"spec": {"featureGates": {"declarativeHotplugVolumes": true}}}'
```

## References

* [Virtualized control planes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/virtualized_control_planes/index)
* [KubeVirt Redfish GitHub](https://github.com/kubevirt/redfish-controller)
