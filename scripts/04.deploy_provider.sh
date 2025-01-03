#!/bin/bash

echo "*** Provider deployment ***"

provider_root="$(builtin cd $(pwd)/..; pwd)/provider"
provider_identity_path="$provider_root/provider-identity"
DID_HELPER="$(pwd)/did-helper"

PRIVATE_KEY="$provider_identity_path/private-key.pem"
PUBLIC_KEY="$provider_identity_path/public-key.pem"
CERTIFICATE="$provider_identity_path/cert.pem"
KEYSTORE="$provider_identity_path/cert.pfx"
DID_KEY="$provider_identity_path/did.key"

echo "Creating provider identity..."

mkdir -p "$provider_identity_path"
# create a new provider identity, if not already exists

# private key
if [ -f $PRIVATE_KEY ]; then
    echo "Private key already exists"
else
    echo "Generating private key..."
    openssl ecparam -name prime256v1 -genkey -noout -out $PRIVATE_KEY
fi

# public key
if [ -f $PUBLIC_KEY ]; then
    echo "Public key already exists"
else
    echo "Generating public key for the private key..."
    openssl ec -in $PRIVATE_KEY -pubout -out $PUBLIC_KEY
fi

# certificate
if [ -f $CERTIFICATE ]; then
    echo "Certificate already exists"
else
    echo "Creating a (self-signed) certificate..."

    # certificate defaults
    COUNTRY=""
    STATE=""
    LOCALITY=""
    ORGNAME=""
    ORGUNIT=""
    DAYS="365"

    # verify the certificate configuration file, if provided
    while getopts ':c:' opt; do
        case $opt in
            c)
                if [ -f "$OPTARG" ]; then
                    source $OPTARG
                    echo "Certificate configuration file $OPTARG loaded."
                else
                    break
                fi
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                ;;
        esac
    done

    subject="/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGNAME/OU=$ORGUNIT"
    openssl req -new -x509 -key $PRIVATE_KEY -out $CERTIFICATE -days $DAYS --subj "$subject"
fi

# keystore
if [ -f $KEYSTORE ]; then
    echo "Keystore already exported."
else
    echo "Exporting keystore..."
    openssl pkcs12 -export -inkey $PRIVATE_KEY -in $CERTIFICATE -out $KEYSTORE -name didPrivateKey -passout pass:test
fi

echo "Verifying keystore content..."
keytool -v -keystore $KEYSTORE -list -alias didPrivateKey -storepass test

# did key
if [ -f $DID_KEY ]; then
    echo "Did key already generated"
else
    if [ ! -f $DID_HELPER ]; then
        echo "Did helper not found. Downloading did-helper..."
        wget https://github.com/wistefan/did-helper/releases/download/0.1.1/did-helper
        chmod +x did-helper
    fi

    echo "Generating did key..."
    ./did-helper -keystorePath $KEYSTORE -keystorePassword=test | grep -o 'did:key:.*' > $DID_KEY

    echo "Provider identity created."
fi

provider_did_key=$(cat $DID_KEY)
echo "Provider DID key: $provider_did_key"

# apply provider identity to values.yaml
echo "Applying provider identity to values.yaml..."
sed -i "s/did:key:.*/$provider_did_key\"/g" $provider_root/values.yaml


echo "Creating provider namespace..."
kubectl create namespace provider 2>/dev/null

echo "Deploying the key into the cluster"
kubectl create secret generic provider-identity --from-file=$KEYSTORE -n provider 2>/dev/null

echo "Deploying the provider..."
helm install provider-dsc data-space-connector/data-space-connector --version 7.17.0 -f $provider_root/values.yaml --namespace=provider

kubectl wait pod --selector=job-name!='tmf-api-registration' --all --for=condition=Ready -n provider --timeout=300s &>/dev/null && kill -INT $(pidof watch) 2>/dev/null &
watch kubectl get pods -n provider

echo -e "*** Provider deployed! ***\n"

cat <<EOF
Next steps:
1. Register the Provider at the Trust Anchor
  - The provider DID key is $provider_did_key
  - Trusted Issuers List API URL: http://til.127.0.0.1.nip.io:8080/issuer
2. Configure the Provider to trust the Consumer (if the consumer is already deployed and registered)
  - Internal Trusted Issuers List URL: http://til-provider.127.0.0.1.nip.io:8080/issuer
  - Provide the Consumer DID key to the request body
3. Configure and register policies to access the data
  - Policy Manager API URL: http://pap-provider.127.0.0.1.nip.io:8080/policy
  - Provide the policy details in the request body
EOF