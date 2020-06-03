#!/bin/bash

set -v
set -e
if [[ -z $VAULT_ADDR ]]; then
    export VAULT_ADDR=https://vault.infra
fi

export VAULT_SKIP_VERIFY=true

if [[ -z $CONSUL_HTTP_ADDR ]]; then
    export CONSUL_HTTP_ADDR=$CONSUL_ADDR:8500
fi

if [[ -z $VAULT_TOKEN ]]; then
    export SERVICE_ACCOUNT_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    export VAULT_PATH=auth/kubernetes/login
    if [ $KUBERNETES_SERVICE_HOST == '172.20.0.1' ] || [ $KUBERNETES_SERVICE_HOST == '10.100.0.1' ]; then
        export VAULT_PATH=auth/eks/login
    fi
    export VAULT_TOKEN=$(vault write $VAULT_PATH role=read jwt=$SERVICE_ACCOUNT_TOKEN | grep -m 1 token | awk '{print $2}')
fi

if [ -z "$VAULT_TOKEN" ]; then
    echo "VAULT_TOKEN not set. Exiting ..."
    exit 1
fi

exec /usr/bin/consul-template "$@"
