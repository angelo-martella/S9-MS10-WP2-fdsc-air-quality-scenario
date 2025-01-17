# Marketplace operations

[Return to index](../README.MD)

## Table of contents

- [Marketplace operations](#marketplace-operations)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Marketplace user wallet](#marketplace-user-wallet)
  - [Policies](#policies)
    - [Allow every authenticated participant to read product offerings](#allow-every-authenticated-participant-to-read-product-offerings)
    - [Allow every authenticated participant to register as customer at the marketplace](#allow-every-authenticated-participant-to-register-as-customer-at-the-marketplace)
    - [Allow the creation of product orders](#allow-the-creation-of-product-orders)
    - [Allow the creation of entities of a given type (K8SCluster) to authenticated participants with a given verifiable credentials type (OperatorCredential)](#allow-the-creation-of-entities-of-a-given-type-k8scluster-to-authenticated-participants-with-a-given-verifiable-credentials-type-operatorcredential)
  - [Offerings catalog management](#offerings-catalog-management)
    - [Create a product specification](#create-a-product-specification)
    - [Get the list of product specifications](#get-the-list-of-product-specifications)
    - [Create a product offering that references a product specification](#create-a-product-offering-that-references-a-product-specification)
    - [Get the list of product offerings](#get-the-list-of-product-offerings)
  - [Consume an offering](#consume-an-offering)
    - [Register Marketplace at Provider and obtain its ID](#register-marketplace-at-provider-and-obtain-its-id)
    - [List the available offerings](#list-the-available-offerings)
    - [Choose and offering and place an order for it](#choose-and-offering-and-place-an-order-for-it)
    - [Interact with the Provider data service to create an entity as an authorized Marketplace Operator](#interact-with-the-provider-data-service-to-create-an-entity-as-an-authorized-marketplace-operator)
    - [Get the created entity](#get-the-created-entity)
  - [Appendix](#appendix)
    - [Errors](#errors)
      - [Unexpected 'code 403 unauthorized' when using a policy that filters for token role](#unexpected-code-403-unauthorized-when-using-a-policy-that-filters-for-token-role)

## Introduction

In the following scenario, a **Provider** participant (*M&P Operations*) offers solutions to host and operate digital services for other companies. A **Consumer** participant (*Fancy Marketplace*) provides a marketplace solution, listing and consuming offers for other companies.

## Prerequisites

The following checklist contains all the requirements that needs to be met in order to ensure a successful communication between all the components involved in the data exchanges between participants of this FIWARE Data Space instance.

- [ ] The cluster is up and running
- [ ] The Trust Anchor, the Consumer and the Provider are fully operational
- [ ] The Consumer and the Provider's DIDs are registered at the Trust Anchor

```txt
TIP: To register the participants at the Trust Anchor it is possible to use the API requests listed in the file api/trust-anchor.http
```

## Marketplace user wallet

Using the script `05.create_wallet.sh` a **wallet identity** for the consumer is created. This wallet allows the creation of verifiable credentials (either for *user* and *operator* scopes), that can be then verified and exchanged for access tokens.

At first, the marketplace allows to consult the list of offerings made available by the Provider using a **user** access token. Once an offering is *accepted* by the user of the Marketplace, it is possible to *use* data service offered by the Provider to create the acquired resource. This happens using an **operator** access token, whose issuance is permitted following the acceptance of the offering.

## Policies

The Marketplace operations workflow is ruled by a set of **policies** that regulate the access to data and services to defined classes of users. The rules are set by interacting with the **ODRL-PAP** service API, posting rules encoded in JSON format that will be interpreted and translated in *rego*. The APISIX's **OPA** sidecar service, that acts as PDP, will then intercept user requests and verify their compliance with the programmed rules.

In the following, the rules to be created for the purposes of this scenario are listed and briefly commented.

```txt
TIP: All the API requests reported in this section are listed in the file api/policy.http
```

### Allow every authenticated participant to read product offerings

```bash
curl -s -X POST http://pap-provider.127.0.0.1.nip.io:8080/policy \
-H 'Content-Type: application/json' \
-d '{ 
        "@context": {
            "dc": "http://purl.org/dc/elements/1.1/",
            "dct": "http://purl.org/dc/terms/",
            "owl": "http://www.w3.org/2002/07/owl#",
            "odrl": "http://www.w3.org/ns/odrl/2/",
            "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
            "skos": "http://www.w3.org/2004/02/skos/core#"
        },
        "@id": "https://mp-operation.org/policy/common/type",
        "@type": "odrl:Policy",
        "odrl:permission": {
            "odrl:assigner": {
                "@id": "https://www.mp-operation.org/"
            },
            "odrl:target": {
                "@type": "odrl:AssetCollection",
                "odrl:source": "urn:asset",
                "odrl:refinement": [
                    {
                        "@type": "odrl:Constraint",
                        "odrl:leftOperand": "tmf:resource",
                        "odrl:operator": {
                            "@id": "odrl:eq"
                        },
                        "odrl:rightOperand": "productOffering"
                    }
                ]
            },
            "odrl:assignee": {
                "@id": "vc:any"
            },
            "odrl:action": {
                "@id": "odrl:read"
            }
        }
    }'
```

### Allow every authenticated participant to register as customer at the marketplace

```bash
curl -s -X POST http://pap-provider.127.0.0.1.nip.io:8080/policy \
-H 'Content-Type: application/json' \
-d '{ 
        "@context": {
            "dc": "http://purl.org/dc/elements/1.1/",
            "dct": "http://purl.org/dc/terms/",
            "owl": "http://www.w3.org/2002/07/owl#",
            "odrl": "http://www.w3.org/ns/odrl/2/",
            "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
            "skos": "http://www.w3.org/2004/02/skos/core#"
        },
        "@id": "https://mp-operation.org/policy/common/type",
        "@type": "odrl:Policy",
        "odrl:permission": {
            "odrl:assigner": {
                "@id": "https://www.mp-operation.org/"
            },
            "odrl:target": {
                "@type": "odrl:AssetCollection",
                "odrl:source": "urn:asset",
                "odrl:refinement": [
                    {
                        "@type": "odrl:Constraint",
                        "odrl:leftOperand": "tmf:resource",
                        "odrl:operator": {
                            "@id": "odrl:eq"
                        },
                        "odrl:rightOperand": "organization"
                    }
                ]
            },
            "odrl:assignee": {
                "@id": "vc:any"
            },
            "odrl:action": {
                "@id": "tmf:create"
            }
        }
    }'
```

### Allow the creation of product orders

```bash
curl -s -X POST http://pap-provider.127.0.0.1.nip.io:8080/policy \
-H 'Content-Type: application/json' \
-d '{ 
        "@context": {
            "dc": "http://purl.org/dc/elements/1.1/",
            "dct": "http://purl.org/dc/terms/",
            "owl": "http://www.w3.org/2002/07/owl#",
            "odrl": "http://www.w3.org/ns/odrl/2/",
            "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
            "skos": "http://www.w3.org/2004/02/skos/core#"
        },
        "@id": "https://mp-operation.org/policy/common/type",
        "@type": "odrl:Policy",
        "odrl:permission": {
            "odrl:assigner": {
                "@id": "https://www.mp-operation.org/"
            },
            "odrl:target": {
                "@type": "odrl:AssetCollection",
                "odrl:source": "urn:asset",
                "odrl:refinement": [
                    {
                        "@type": "odrl:Constraint",
                        "odrl:leftOperand": "tmf:resource",
                        "odrl:operator": {
                            "@id": "odrl:eq"
                        },
                        "odrl:rightOperand": "productOrder"
                    }
                ]
            },
            "odrl:assignee": {
                "@id": "vc:any"
            },
            "odrl:action": {
                "@id": "tmf:create"
            }
        }
    }'
```

### Allow the creation of entities of a given type (K8SCluster) to authenticated participants with a given verifiable credentials type (OperatorCredential)

```bash
curl -s -X POST http://pap-provider.127.0.0.1.nip.io:8080/policy \
-H 'Content-Type: application/json' \
-d '{
        "@context": {
            "dc": "http://purl.org/dc/elements/1.1/",
            "dct": "http://purl.org/dc/terms/",
            "owl": "http://www.w3.org/2002/07/owl#",
            "odrl": "http://www.w3.org/ns/odrl/2/",
            "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
            "skos": "http://www.w3.org/2004/02/skos/core#"
        },
        "@id": "https://mp-operation.org/policy/common/type",
        "@type": "odrl:Policy",
        "odrl:permission": {
            "odrl:assigner": {
                "@id": "https://www.mp-operation.org/"
            },
            "odrl:target": {
                "@type": "odrl:AssetCollection",
                "odrl:source": "urn:asset",
                "odrl:refinement": [
                    {
                        "@type": "odrl:Constraint",
                        "odrl:leftOperand": "ngsi-ld:entityType",
                        "odrl:operator": {
                            "@id": "odrl:eq"
                        },
                        "odrl:rightOperand": "K8SCluster"
                    }
                ]
            },
            "odrl:assignee": {
                "@type": "odrl:PartyCollection",
                "odrl:source": "urn:user",
                "odrl:refinement": {
                    "@type": "odrl:Constraint",
                    "odrl:leftOperand": {
                        "@id": "vc:type"
                    },
                    "odrl:operator": {
                        "@id": "odrl:hasPart"
                    },
                    "odrl:rightOperand": {
                        "@value": "OperatorCredential",
                        "@type": "xsd:string"
                    }
                }
            },
            "odrl:action": {
                "@id": "odrl:use"
            }
        }
    }'
```

## Offerings catalog management

Essentially, the Provider allows the management of the catalog of products and their corresponding offerings through the TM-Forum API. In this scenario, products can be managed and, for any given **product specification**, it is possible to create **product offerings**.

In the following, the API requests to manage the product catalog.

```txt
TIP: All the API requests reported in this section are listed in the file api/provider.http
```

### Create a product specification

```bash
curl -s -X POST http://tm-forum-api.127.0.0.1.nip.io:8080/tmf-api/productCatalogManagement/v4/productSpecification \
-H 'content-type: application/json;charset=utf-8' \
-d '{
        "name": "M&P K8S",
        "brand": "M&P Operations",
        "version": "1.0.0",
        "lifecycleStatus": "ACTIVE"
    }'
```

### Get the list of product specifications

```bash
curl -s -X GET http://tm-forum-api.127.0.0.1.nip.io:8080/tmf-api/productCatalogManagement/v4/productSpecification
```

### Create a product offering that references a product specification

```bash
curl -s -X POST http://tm-forum-api.127.0.0.1.nip.io:8080/tmf-api/productCatalogManagement/v4/productOffering \
-H 'content-type: application/json;charset=utf-8' \
-d '{
        "name": "M&P K8S Offering",
        "version": "1.0.0",
        "productSpecification": {
            "id": "{{PRODUCT-SPEC-ID}}"
        },
        "lifecycleStatus": "ACTIVE"
    }'
```

### Get the list of product offerings

```bash
curl -s -X POST http://tm-forum-api.127.0.0.1.nip.io:8080/tmf-api/productCatalogManagement/v4/productOffering
```

## Consume an offering

To allow the consultation of the product offerings catalog, the Marketplace Consumer must first register as *organization* at the Provider's TM-Forum service. Such a service is protect by an authentication layer, thus API requests to the TM-Forum service must include a proper access token for the verifiable credentials related to the *user* scope.

The following command issues an access token for the **user**:

```bash
./get_access_token_oid4vp.sh http://mp-data-service.127.0.0.1.nip.io:8080 $USER_CREDENTIAL user path/to/wallet/identity
```

```txt
NOTE: The issuance of access tokens for the operator role is allowed only after an offering is accepted.
```

Similarly, once an order is placed for a chosen offering, the marketplace can acquire an **operator access token** using the following command:

```bash
./get_access_token_oid4vp.sh http://mp-data-service.127.0.0.1.nip.io:8080 $OPERATOR_CREDENTIAL user path/to/wallet/identity
```

In the following, the API requests to interact with the Provider on behalf of the Marketplace Consumer are listed and briefly commented.

```txt
TIP: All the API requests reported in this section are listed in the file api/marketplace.http
```

### Register Marketplace at Provider and obtain its ID

```bash
curl -s -X POST http://mp-tmf-api.127.0.0.1.nip.io:8080/tmf-api/party/v4/organization \
-H 'Accept: */*' \
-H 'Content-Type: application/json' \
-H 'Authorization: Bearer {{USER_ACCESS_TOKEN}}' \

-d '{
        "name": "Fancy Marketplace Inc.",
        "partyCharacteristic": [
            {
                "name": "did",
                "value": "{{CONSUMER-DID}}"
            }
        ]
    }'
```

### List the available offerings

```bash
curl -s -X GET http://mp-tmf-api.127.0.0.1.nip.io:8080/tmf-api/productCatalogManagement/v4/productOffering \
-H 'Authorization: Bearer {{USER_ACCESS_TOKEN}}'
```

### Choose and offering and place an order for it

```bash
curl -s -X POST http://mp-tmf-api.127.0.0.1.nip.io:8080/tmf-api/productCatalogManagement/v4/productOrder \
-H 'Accept: */*' \
-H 'Content-Type: application/json' \
-H 'Authorization: Bearer {{USER_ACCESS_TOKEN}}' \

-d '{
        "productOrderItem": [
            {
                "id": "random-order-id",
                "action": "add",
                "productOffering": {
                    "id":  "{{OFFER-ID}}"
                }
            }
        ],
        "relatedParty": [
            {
                "id": "{{MARKETPLACE-ID}}"
            }
        ]
    }'
```

At this point, the ContractManagement service has been notified by TMForum, an entry has been created in the TrustedIssuersList and, therefore, the Consumer Marketplace can access the Provider services with an Operator credential. Thus, an **operator access token** can be issued and embedded in the following requests to interact with the Provider's data service. To issue an operator token, refer to the command reported [above](#consume-an-offering).

### Interact with the Provider data service to create an entity as an authorized Marketplace Operator

```bash
curl -s -X POST http://mp-data-service.127.0.0.1.nip.io:8080/ngsi-ld/v1/entities \
-H 'Accept: */*' \
-H 'Content-Type: application/json' \
-H 'Authorization: Bearer {{OPERATOR_ACCESS_TOKEN}}' \

-d '{
        "id": "urn:ngsi-ld:K8SCluster:fancy-marketplace",
        "type": "K8SCluster",
        "name": {
            "type": "Property",
            "value": "Fancy Marketplace Cluster"
        },
        "numNodes": {
            "type": "Property",
            "value": "3"
        },
        "k8sVersion": {
            "type": "Property",
            "value": "1.26.0"
        }
    }'
```

### Get the created entity

```bash
curl -s -X GET http://mp-data-service.127.0.0.1.nip.io:8080/ngsi-ld/v1/entities/{{ENTITY-ID}}
-H 'Accept: */*' \
-H 'Authorization: Bearer {{OPERATOR_ACCESS_TOKEN}}'
```

## Appendix

### Errors

#### Unexpected 'code 403 unauthorized' when using a policy that filters for token role

When setting a policy assignee to filter requests based on given user `vc:role` included in the token's payload (such as *OPERATOR* or *USER*), the PDP does not grant the access to the resource, even if the JWT token is correcly formatted.

Quick fix: set the policy assignee constraint to `vc:type`.

[Return to index](../README.MD)
