# FIWARE Data Space Connector technical docs

[Trust Anchor](trust-anchor/TRUST-ANCHOR.MD)

[Data Consumer](consumer/CONSUMER.MD)

[Data Provider](provider/PROVIDER.MD)

## Setup k3s cluster

```bash
sudo systemctl stop k3s.service

cd base-cluster

mvn clean deploy

export KUBECONFIG=<PROJECT_HOME>/base-cluster/target/k3s.yaml
```

Replace PROJECT_HOME with full path to the project. Can be `$(pwd)` from the project root.

### Enable storage

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml
```

## Ready-to-use scripts

The whole setup and deployment of the FDSC instance presented in this documentation can be streamlined by using the quick deployment scripts located in the script folder:

* 01.deploy_cluster.sh
* 02.deploy_trust_anchor.sh
* 03.deploy_consumer.sh
* 04.deploy_provider.sh
* 05.create_wallet.sh

An additional maintenance script called `00.cleanup.sh` allows to uninstall the environment and even purge the cluster, if necessary.

The usage of the quick deployment and cleanup scripts is detailed [here](SCRIPTS.MD).

## Appendix

### Diagnosis tools

#### List pods running in a given NAMESPACE

```bash
kubectl get pods -n <NAMESPACE>
```

#### Show logs of a POD runnin in a given NAMESPACE

```bash
kubectl logs <POD> -n <NAMESPACE>
```

### Errors

#### Enable storage failed

After executing `kubectl apply` command, the following error arises:

```bash
tls: failed to verify certificate: x509: certificate signed by unknown authority; if you choose to ignore these errors, turn validation off with --validate=false
```

Solution: verify that the KUBECONFIG path is exported correctly.
