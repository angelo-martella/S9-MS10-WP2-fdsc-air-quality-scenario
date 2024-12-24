# Trust Anchor

[Return to index](../README.MD)

## Table of Contents

- [Trust Anchor](#trust-anchor)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Configuration values.yaml](#configuration-valuesyaml)
    - [MySql](#mysql)
    - [Trusted Issuers List](#trusted-issuers-list)
  - [Deployment of the Trust Anchor](#deployment-of-the-trust-anchor)
    - [1. Render the template](#1-render-the-template)
    - [2. Create 'trust-anchor' namespace](#2-create-trust-anchor-namespace)
    - [3. Install the Trust Anchor](#3-install-the-trust-anchor)
    - [(Alternatively) Apply rendered templates](#alternatively-apply-rendered-templates)
  - [Usage](#usage)
    - [Use TIL API to register a participant to the Trust Anchor](#use-til-api-to-register-a-participant-to-the-trust-anchor)
    - [Use TIR API to fetch the global trusted issuers list](#use-tir-api-to-fetch-the-global-trusted-issuers-list)
  - [Uninstall](#uninstall)
  - [Appendix](#appendix)
    - [Errors](#errors)
      - [Application of rendered templates fails](#application-of-rendered-templates-fails)

## Introduction

The Trust Anchor includes **Trusted Issuers List (TIL)** to provide 2 APIs:

- EBSI Trusted Issuers Registry (TIR) API
- TIL API for registration

**MySql** acts as a storage backend for the participants.

![alt text](<img/01.png>)

## Configuration values.yaml

### MySql

```yaml
# -- configuration for the mysql to be deployed as part of the trust-anchor, see https://github.com/bitnami/charts/tree/main/bitnami/mysql for all options
mysql:
  # -- should it be enabled? set to false if one outside the chart is used.
  enabled: true

  # -- configure persistence, depending on the storageClasses available in your cluster
  primary:
    persistence:
      # use one of the classes provided by your cluster
      storageClass: local-path

  ## defaults

  # -- allows to set a fixed name for the services
  fullnameOverride: trust-anchor-mysql
  # -- configure authentication to mysql
  auth:
    # -- name of the secret to take the passowrds from
    existingSecret: mysql-database-secret
  # -- scripts to be executed on db startup
  initdbScripts:
    create.sql: |
      CREATE DATABASE tirdb;
```

### Trusted Issuers List

```yaml
# -- configuration for the trusted-issuers-list to be deployed as part of the trust-anchor, see https://github.com/FIWARE/helm-charts/tree/main/charts/trusted-issuers-list for all options
trusted-issuers-list:
  # -- should it be enabled? set to false if one outside the chart is used.
  enabled: true

  # -- configuration to make the list "publicly" accessible through our ingress controller
  ingress:
    tir:
      enabled: true
      hosts:
        - host: tir.127.0.0.1.nip.io
    til:
      enabled: true
      hosts:
        - host: til.127.0.0.1.nip.io

  ## defaults

  # -- allows to set a fixed name for the services
  fullnameOverride: tir
  # -- connection to the database
  database:
    # -- should persistence be used?
    persistence: true
    # -- name of the db user
    username: root
    # -- configuration for the existing secret to get the passwords from
    existingSecret: 
      enabled: true
      name: mysql-database-secret
      key: mysql-root-password
    # -- host of the database
    host:  trust-anchor-mysql
    # -- name of the schema inside the db
    name: tirdb
```

## Deployment of the Trust Anchor

### 1. Render the template
<!--
the command
```
helm template data-space-connector/trust-anchor --version 2.0.0 -f values.yaml --name-template=trust-anchor --namespace=trust-anchor --output-dir rendered
```
originally reported the argument --version 2.2.0, but this version tag is not available for the data-space-connector repository added through the command
```
helm repo add data-space-connector https://fiware.github.io/data-space-connector/
```
-->
```bash
helm repo add data-space-connector https://fiware.github.io/data-space-connector/

cd trust-anchor

helm template data-space-connector/trust-anchor --version 2.0.0 -f values.yaml --name-template=trust-anchor --namespace=trust-anchor --output-dir rendered
```

### 2. Create 'trust-anchor' namespace

```bash
kubectl create namespace trust-anchor
```

### 3. Install the Trust Anchor

```bash
helm install trust-anchor-dsc data-space-connector/trust-anchor --version 2.0.0 -f values.yaml --namespace=trust-anchor

watch kubectl get pods -n trust-anchor
```

### (Alternatively) Apply rendered templates

If helm template was executed, this can be used to apply all files in the folder

```bash
kubectl apply -R -f rendered/

watch kubectl get pods -n trust-anchor
```

## Usage

### Use TIL API to register a participant to the Trust Anchor

```bash
curl -X POST http://til.127.0.0.1.nip.io:8080/issuer \
    --header 'Content-Type: application/json' \
    --data '{
      "did": "did:key:<PARTICIPANT-KEY>",
      "credentials": []
    }'
```

### Use TIR API to fetch the global trusted issuers list

```bash
curl -X GET http://tir.127.0.0.1.nip.io:8080/v4/issuers
```

## Uninstall

```bash
helm uninstall trust-anchor-dsc -n trust-anchor
```

## Appendix

### Errors

#### Application of rendered templates fails

The command `kubectl apply -R -f rendered/` fails with the following error:

```bash
[output truncated...]
Error from server (Invalid): error when applying patch:
[output truncated...]
error when patching "rendered/trust-anchor/charts/trusted-issuers-list/templates/deployment.yaml": Deployment.apps "tir" is invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/instance":"trust-anchor", "app.kubernetes.io/name":"trusted-issuers-list"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable
```

Solution:

1. Delete the existing resource

    ```bash
    kubectl delete -R -f rendered/
    ```

2. Recreate the resource

    ```bash
    kubectl apply -R -f rendered/
    ```

[Return to index](../README.MD)
