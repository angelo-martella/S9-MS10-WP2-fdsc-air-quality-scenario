#!/bin/bash

echo "*** Wallet identity creation ***"

wallet_path="$(builtin cd $(pwd)/..; pwd)/consumer/wallet-identity"
role="operator"

echo "Preparing wallet identity (identity of the user that acts on behalf of the consumer)..."
mkdir -p "$wallet_path"
chmod o+rw "$wallet_path"

docker run -v $wallet_path:/cert quay.io/wi_stefan/did-helper:0.1.1 | grep -o 'did:key:.*' > $wallet_path/did.key

while getopts ':c:' opt; do
    case $opt in
        c)
            if [ -z "$OPTARG" ]; then
                user_credential=$OPTARG
            else
                echo "No user credential provided."
                exit 1
            fi
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done

if [ $# -eq 0 ] && [ ! -z $USER_CREDENTIAL ]; then
    user_credential=$USER_CREDENTIAL
else
    echo "No USER_CREDENTIAL provided."
    exit 1
fi

echo "Exchanging access token..."
access_token=$(./get_access_token_oid4vp.sh http://mp-data-service.127.0.0.1.nip.io:8080 $user_credential $role $wallet_path)

if $(return 0 2>/dev/null); then
    echo "Exporting ACCESS_TOKEN..."
    export ACCESS_TOKEN=$access_token
    echo $ACCESS_TOKEN
else
    echo -e "Access token generated. You can export it by running\n\nexport ACCESS_TOKEN=$access_token\n"
fi

echo -e "\n*** Wallet identity created! ***"
echo -e "Now it is possible to embed the access token as bearer token in the Authorization header of the HTTP requests to the Data Provider."