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

#### Unable to generate access token

The creation of access token for a given user credential returns `null`.

This can be caused by a misconfiguration of the DID keys included in the participants' `values.yaml` files. Another potential issue is the incorrect registration of the participants at the Trust Anchor. Lastly, it is possible that the **scope** of the requested token is not recognized/configured in the FDSC instance, or that the user credential was created for a different scope.

Beware that in the default configuration access tokens are **disposable**, meaning that they can be only *consumed* once. Thus, for each interaction with the data provider's APIs, a new access token must be generated and embedded into the request. On top of this, it is not possible to generate a new token before consuming the one that has been generated for a given request. Attempting to do it would result into a **null** response.

Solution: to fix this issue, check the following conditions:

* The `values.yaml` files include the correct DID keys.
* The participants are correctly registered at the Trust Anchor before attempting to generate an access token.
* Check the **scope** of the user credentials (*user-credential* or *operator-credential*, in the default configuration) and make sure it matches the scope of the corresponding access token request (namely *user* or *operator*)
* Check whether the requested scope is properly configured in the keycloak realm included in the `values.yaml` file of the consumer.
* Make sure that only one access token was generated for a given request and that any token was consumed before attempting to obtain a new one.
