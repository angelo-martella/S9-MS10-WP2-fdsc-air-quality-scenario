#!/bin/bash

echo "*** Wallet identity creation ***"

wallet_path=$(builtin cd $(pwd)/..; pwd)/wallet-identity
scope="user"
user_credential=""

while getopts 'c:p:s:' opt; do
    echo "Option: $opt"
    echo "OPTARG: $OPTARG"
    case $opt in
        c)
            if [ ! -z $OPTARG ]; then
                user_credential=$OPTARG
            else
                echo "No user credential argument provided."
                return 1
            fi
            ;;
        p)
            if [ ! -z $OPTARG ] && [ -d $OPTARG ]; then
                wallet_path=$(cd $OPTARG; pwd)
            else
                echo "No wallet path provided."
                return 1
            fi
            ;;
        s)
            if [ ! -z $OPTARG ]; then
                scope=$OPTARG
            else
                echo "No scope argument provided."
                return 1
            fi
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            return 1
            ;;
    esac
done

if [ -z $user_credential ]; then
    echo "No user credential provided."
    return 1
fi

echo "Preparing wallet identity (identity of the user that acts on behalf of the consumer)..."
mkdir -p "$wallet_path"
chmod o+rw "$wallet_path"

docker run -v $wallet_path:/cert quay.io/wi_stefan/did-helper:0.1.1 | grep -o 'did:key:.*' > $wallet_path/did.key

echo -e "\nUser credential:\n$user_credential\n"
echo -e "Wallet path: $wallet_path\n"
echo -e "Scope: $scope\n"

echo "Exchanging access token..."
access_token=$(./get_access_token_oid4vp.sh http://mp-data-service.127.0.0.1.nip.io:8080 $user_credential $scope $wallet_path)

if $(return 0 2>/dev/null); then
    echo "Exporting ACCESS_TOKEN..."
    export ACCESS_TOKEN=$access_token
    echo -e "Access token:\n$ACCESS_TOKEN\n"
else
    echo -e "Access token generated. You can export it by running\n\nexport ACCESS_TOKEN=$access_token\n"
fi

echo -e "\n*** Wallet identity created! ***"
echo -e "Now it is possible to embed the access token as bearer token in the Authorization header of the HTTP requests to the Data Provider."