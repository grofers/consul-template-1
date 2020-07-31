#!/bin/sh

set -v
set -e
export VAULT_ADDR=https://vault.infra
export VAULT_SKIP_VERIFY=true
export CONSUL_HTTP_ADDR=$CONSUL_ADDR:8500
export SERVICE_ACCOUNT_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# TODO: Read the vault path from service in future
# a vault path should end with login. If the path is /auth/temp/login,
# the CNAME must be auth.temp (do not end the login in end)
if [ ! "$ENV" == "local" ]; then
    SERVICE_URL="vault-path.infra.svc.cluster.local"

    VAULT_PATH="$(dig $SERVICE_URL | grep 'CNAME' | cut -d ' ' -f 4 | awk '{print $2}' | sed 's/\./\//g')"

    export VAULT_TOKEN=$(vault write $VAULT_PATH"login" role=read jwt=$SERVICE_ACCOUNT_TOKEN | grep -m 1 token | awk '{print $2}')
    if [ -z "$VAULT_TOKEN" ]; then
        echo "VAULT_TOKEN not set. Exiting ..."
        exit 1
    fi
fi

exec /bin/consul-template "$@"
