# Descheduler

The KubeVirtRelieveAndMigrate profile requires PSI metrics to be enabled on cluster nodes. To enable PSI, use
the openshift_cluster_postinstall role to add kernel parameter psi=1 to MachineConfig.spec.kernelArguments.

## References

* [Enabling descheduler evictions on virtual machines](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/virtualization/managing-vms#virt-enabling-descheduler-evictions)
