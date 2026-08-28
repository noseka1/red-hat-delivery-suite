# Red Hat Delivery Suite

This repository contains scripts, tools, and sample configurations used in Red Hat Services delivery projects. The repository is especially useful in these scenarios:
* Configuration reference for customer environments
* Building a lab environment for self-education
* Reproducing production issues in an isolated lab environment
* Trying out proof-of-concept deployments and configurations
* Creating customer demo and teaching sessions

By default, the repository is designed to support single-node OpenShift clusters to ensure simplicity and preserve compute resources. Nevertheless, the Ansible roles are parameterized to accommodate larger scale deployments as well.

## Setup

Install dependencies with:

```
$ ansible-galaxy role install \
  --role-file requirements_community.yml \
  --force
```

```
$ ansible-galaxy collection install \
  --requirements-file requirements_community.yml \
  --force
```

Optionally, install Red Hat dependencies using:

```
$ export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN="<Insert your secret token that you downloaded from https://console.redhat.com/ansible/automation-hub/token>"
```

Note that the token will expire after 30 days of inactivity.

```
$ ansible-galaxy collection install \
  --requirements-file requirements_redhat.yml \
  --force
```

Insert your credentials:

```
$ cp inventory/group_vars/all/credentials.yml.sample inventory/group_vars/all/credentials.yml
$ vi inventory/group_vars/all/credentials.yml
```

Optionally, add custom configurations into `./inventory` directory.

## Deploying OpenShift cluster

Deploy OpenShift cluster to AWS, Azure, GCP, or bare metal using the [openshift_cluster_install](roles/openshift_cluster_install/docs/README.md) role. Define the necessary variables in your Ansible inventory and execute:

```
$ ansible-playbook -i inventory/localhost.yml openshift_cluster_install_aws_deploy.yml
```

## Configuring OpenShift after installation

Define the necessary variables in your Ansible inventory and issue:

```
$ ansible-playbook -i inventory/localhost.yml openshift_cluster_postinstall.yml
```

## Deploying AutoGitOps

Most of the OpenShift operators in this repo are deployed using [AutoGitOps](roles/openshift_autogitops/docs/autogitops.md). Before deploying any of the OpenShift operators, you must deploy AutoGitOps to your cluster. You can deploy AutoGitOps using the command:

```
$ ansible-playbook -i inventory/localhost.yml openshift_autogitops_deploy.yml
```

## Deploying OpenShift operators

You can run Ansible playbook to deploy OpenShift operators:

```
$ ansible-playbook -i inventory/localhost.yml <playbook>
```

For example, to deploy NMState operator along with the respective instance, you can issue:

```
$ ansible-playbook -i inventory/localhost.yml openshift_nmstate_deploy.yml
```

To uninstall NMState instance and the operator, issue:

```
$ ansible-playbook -i inventory/localhost.yml openshift_nmstate_delete.yml
```

To get a list of available tags for deploying individual components, issue:

```
$ ansible-playbook -i inventory/localhost.yml openshift_nmstate_deploy.yml --list-tags
```

```
playbook: openshift_nmstate_deploy.yml

  play #1 (localhost): localhost        TAGS: []
        TASK TAGS: [nmstate_instance, nmstate_operator]
```

To deploy just the NMState operator, issue:

```
$ ansible-playbook -i inventory/localhost.yml openshift_nmstate_deploy.yml --tags nmstate_operator
```

To uninstall just the NMState operator, issue:

```
$ ansible-playbook -i inventory/localhost.yml openshift_nmstate_delete.yml --tags nmstate_operator
```
