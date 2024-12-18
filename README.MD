# FIWARE Data Space Connector technical docs

[Trust Anchor](doc/trust-anchor/TRUST-ANCHOR.MD)

[Data Consumer](doc/consumer/CONSUMER.MD)

[Data Provider](doc/provider/PROVIDER.MD)

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

## Appendix

### Error - Enable storage

After executing the command, the following error arises:

```bash
tls: failed to verify certificate: x509: certificate signed by unknown authority; if you choose to ignore these errors, turn validation off with --validate=false
```

Solution: remember to export the correct KUBECONFIG path!