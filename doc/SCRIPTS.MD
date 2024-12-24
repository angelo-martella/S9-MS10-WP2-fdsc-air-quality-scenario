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
COUNTRY=""  # 2 letter country-code (e.g DE)
STATE=""    # state or province name
LOCALITY="" # Locality Name (e.g. city)
ORGNAME=""  # Organization Name (eg, company)
ORGUNIT=""  # Organizational Unit Name (eg. section)
```

If it is not passed, the script proceeds non interactively to generate a certificate without specifying any information.

### Example: consumer certificate.conf

The file `consumer/.certificate.conf` includes the following configuration:

```conf
COUNTRY="DE"
STATE="Hamburg"
LOCALITY="Hamburg"
ORGNAME="FIWARE"
ORGUNIT="Consumer"
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
COUNTRY=""  # 2 letter country-code (e.g DE)
STATE=""    # state or province name
LOCALITY="" # Locality Name (e.g. city)
ORGNAME=""  # Organization Name (eg, company)
ORGUNIT=""  # Organizational Unit Name (eg. section)
```

If it is not passed, the script proceeds non interactively to generate a certificate without specifying any information.

### Example: provider certificate.conf

The file `provider/.certificate.conf` includes the following configuration:

```conf
COUNTRY="IT"
STATE="Lecce"
LOCALITY="Lecce"
ORGNAME="Unisalento"
ORGUNIT="Provider"
```

Run the script `04.deploy_provider.s` with the proper path to the conf file.

```bash
./04.deploy_provider.s -c ../provider/.certificate.conf
```

## Wallet identity creation

By running the script `05.create_wallet.sh`, it is possible to create a wallet for the user that will interact with the data provider on behalf of the consumer.

```bash
[source] ./05.create_wallet.sh [-c user-credential]
```

The user credential can be either passed as argument following the `-c` option, or through the `USER_CREDENTIAL` environment variable set after the deployment of the consumer (thus omitting the `-c` option in this case).

The script can be sourced to export the exchanged access token into the `ACCESS_TOKEN` environment variable, or executed normally. In the latter case, the export command is returned on the console.

The resulting token can then be embedded as bearer token in the authorization header of the HTTP requests to the data provider.

## Cleanup script

Run the script `00.cleanup.sh` to uninstall the deployed pods, remove the namespaces and delete the persistent volumes.

```bash
[source] ./00.cleanup.sh [-f]
```

With the `-f` flag the script forces the disintallation of the cluster, by removing the `k3s-maven-plugin` docker container and the corresponding volumes.

Additionally, the script can be sourced to restore the default system KUBECONFIG, if exists. If it is not sourced, the script will output the export command with the default path to KUBECONFIG for the user to prompt it.

[Return to index](./README.MD)
