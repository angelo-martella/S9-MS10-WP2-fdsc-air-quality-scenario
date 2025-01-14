# Scripts usage guide

[Return to index](./README.MD)

## Table of Contents

- [Scripts usage guide](#scripts-usage-guide)
  - [Table of Contents](#table-of-contents)
  - [k3s cluster deployment](#k3s-cluster-deployment)
  - [Trust Anchor deployment](#trust-anchor-deployment)
  - [Consumer deployment](#consumer-deployment)
    - [Example: consumer certificate.conf](#example-consumer-certificateconf)
  - [Provider deployment](#provider-deployment)
    - [Example: provider certificate.conf](#example-provider-certificateconf)
  - [Wallet identity creation](#wallet-identity-creation)
    - [Generating verifiable credentials](#generating-verifiable-credentials)
  - [Cleanup script](#cleanup-script)

## k3s cluster deployment

Run the script `01.deploy_cluster.sh` performs all the operations required to configure and deploy a base k3s cluster.

```bash
[source] ./01.deploy_cluster.sh
```

The script can be sourced to export the KUBECONFIG variable automatically.

```bash
source ./01.deploy_cluster.sh
```

Alternatively, it is possible to run the script and export the KUBECONFIG variable manually.

```bash
./01.deploy_cluster.sh

export KUBECONFIG=$(builtin cd $(pwd)/..; pwd)/base-cluster/target/k3s.yaml
```

## Trust Anchor deployment

Run the script `02.deploy_trust_anchor.sh`.

```bash
./02.deploy_trust_anchor.sh
```

## Consumer deployment

Run the script `03.deploy_consumer.sh`.

```bash
./03.deploy_consumer.sh [-c /path/to/certificate/details]
```

The argument following the option `-c` is optional. If passed, it allows the script to generate a certificate non interactively using the information included in a configuration file, whose content matches the following template:

```conf
COUNTRY=""    # 2 letter country-code (e.g DE)
STATE=""      # state or province name
LOCALITY=""   # Locality Name (e.g. city)
ORGNAME=""    # Organization Name (eg, company)
ORGUNIT=""    # Organizational Unit Name (eg. section)
COMMONNAME="" # Common Name
```

If it is not passed, the script proceeds non interactively to generate a certificate without specifying any information.

### Example: consumer certificate.conf

The file `consumer/.certificate.conf` contains the following configuration:

```conf
COUNTRY="BE"
STATE="BRUSSELS"
LOCALITY="Brussels"
ORGNAME="Fancy Marketplace Co."
ORGUNIT="Consumer"
COMMONNAME="www.fancy-marketplace.biz"
```

Run the script `03.deploy_consumer.sh` with the proper path to the conf file.

```bash
./03.deploy_consumer.sh -c ../consumer/.certificate.conf
```

## Provider deployment

Run the script `04.deploy_provider.sh`.

```bash
./04.deploy_provider.sh [-c /path/to/certificate/details]
```

As per the consumer deployment script, the argument following the option `-c` is optional. If passed, it allows the script to generate a certificate non interactively using the information included in a configuration file, whose content matches the following template:

```conf
COUNTRY=""    # 2 letter country-code (e.g DE)
STATE=""      # state or province name
LOCALITY=""   # Locality Name (e.g. city)
ORGNAME=""    # Organization Name (eg, company)
ORGUNIT=""    # Organizational Unit Name (eg. section)
COMMONNAME="" # Common Name
```

If it is not passed, the script proceeds non interactively to generate a certificate without specifying any information.

### Example: provider certificate.conf

The file `provider/.certificate.conf` contains the following configuration:

```conf
COUNTRY="DE"
STATE="Saxony"
LOCALITY="Dresden"
ORGNAME="M&P Operations Inc."
ORGUNIT="Provider"
COMMONNAME="www.mp-operation.org"
```

Run the script `04.deploy_provider.sh` with the proper path to the conf file.

```bash
./04.deploy_provider.sh -c ../provider/.certificate.conf
```

## Wallet identity creation

By running the script `05.create_wallet.sh`, it is possible to create a wallet for the user that will interact with the data provider on behalf of the consumer.

```bash
[source] ./05.create_wallet.sh [-p wallet-path]
```

With the option `-p` it is possible to specify the root directory where the wallet will be created (defaults to *PROJECT_HOME/wallet-identity*).

The script supports the issuance of verifiable credentials for **USER** and **OPERATOR** scopes, according to the scopes defined at *scorpio/ccs/oidcScopes* in provider's values.yaml.

The script can be sourced to export the issued verified credentials as the `USER_CREDENTIAL` and `OPERATOR_CREDENTIAL` environment variables, or executed normally. In the latter case, the export commands are returned on the console.

The resulting token can then be embedded as bearer token in the authorization header of the HTTP requests to the data provider.

### Generating verifiable credentials

A required argument is the verifiable credential of the user or operator that intends to act on behalf of the consumer.

To get the **UserCredential**:

```bash
export USER_CREDENTIAL=$(./get_credential_for_consumer.sh http://keycloak-consumer.127.0.0.1.nip.io:8080 user-credential); echo ${USER_CREDENTIAL}
```

Similarly, to get the **OperatorCredential**:

```bash
export OPERATOR_CREDENTIAL=$(./get_credential_for_consumer.sh http://keycloak-consumer.127.0.0.1.nip.io:8080 operator-credential); echo ${OPERATOR_CREDENTIAL}
```

## Cleanup script

Run the script `00.cleanup.sh` to uninstall the deployed pods, remove the namespaces and delete the persistent volumes.

```bash
[source] ./00.cleanup.sh [-p -f]
```

With the `-p` flag, following the uninstallation of the deployed pods, the script deletes the persistent volumes.

With the `-f` flag the script forces the uninstallation of the cluster, by removing the `k3s-maven-plugin` docker container and the corresponding volumes.

Additionally, the script can be sourced to restore the default system KUBECONFIG, if exists. If it is not sourced, the script will output the export command with the default path to KUBECONFIG for the user to prompt it.

[Return to index](./README.MD)
