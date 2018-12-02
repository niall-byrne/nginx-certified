#!/bin/bash

# -----------------------------------------------------------
# Deyhydrated - integrated with Vault for secret storage
# Maintained by:  niall@sharedvisionsolutions.com
# -----------------------------------------------------------


# -----------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------

# Required Variables:

# DNS_EMAIL
# SUBDOMAIN
# HOSTED_ZONE
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# PRODUCTION (0 or 1)

echo "BOOTSTRAP: Configuring the Let's Encrypt Environment ... "

error() {
    echo "ERROR: The environment variable $1 is not defined!"
}

PORT="<<port>>"

[[ -z ${DNS_EMAIL} ]] && error DNS_EMAIL
[[ -z ${SUBDOMAIN} ]] && error SUBDOMAIN
[[ -z ${HOSTED_ZONE} ]] && error HOSTED_ZONE
[[ -z ${AWS_ACCESS_KEY_ID} ]] && error AWS_ACCESS_KEY_ID
[[ -z ${AWS_SECRET_ACCESS_KEY} ]] && error AWS_SECRET_ACCESS_KEY

PRODUCTION_ENVIRONMENT=${PRODUCTION:-0}

[[ ${PRODUCTION_ENVIRONMENT} -eq 0 ]] && DEHYDRATED_CA="https://acme-staging-v02.api.letsencrypt.org/directory"
[[ ${PRODUCTION_ENVIRONMENT} -eq 1 ]] && DEHYDRATED_CA="https://acme-v02.api.letsencrypt.org/directory"
echo "BOOTSTRAP: Let's Encrypt Endpoint set to ${DEHYDRATED_CA} ..."
echo "BOOTSTRAP: Proxying to 127.0.0.1:${PORT} ..."

# -----------------------------------------------------------
# Functions
# -----------------------------------------------------------

wait_for_backend() {
    echo "BOOTSTRAP: Waiting for backend ..."
    while true; do
        nc -z 127.0.0.1 ${PORT}
        [[ $? -eq 0 ]] && break
        sleep 1
    done
    echo "BOOTSTRAP: Backend is ready."
}

register() {

    [[ -f /opt/dehydrated/READY ]] && return

    echo "*****************************************"
    echo "* Registering with Let's Encrypt ...    *"
    echo "*****************************************"

    cd /opt/dehydrated

    # Create a manifest file here
    cd /opt/dehydrated
    echo "${SUBDOMAIN}.${HOSTED_ZONE}"                              > /opt/dehydrated/domains.txt
    echo "export HOSTED_ZONE=${HOSTED_ZONE}"                        > /opt/dehydrated/config
    echo "export CA='${DEHYDRATED_CA}'"                             >> /opt/dehydrated/config
    echo "export CONTACT_EMAIL='${DNS_EMAIL}'"                      >> /opt/dehydrated/config
    echo "export HOOK='hooks/aws/hook.py'"                          >> /opt/dehydrated/config
    echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"            >> /opt/dehydrated/config
    echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"    >> /opt/dehydrated/config

    # Finish renewal
   ./dehydrated --register --accept-terms

    touch /opt/dehydrated/READY

}

renew() {

    if [[ ! -f /opt/dehydrated/READY ]]; then

        echo "ERROR: registration with Let's Encrypt has failed."

    else

        echo "*****************************************"
        echo "* Renewing certificates ...             *"
        echo "*****************************************"

        cd /opt/dehydrated
        ./dehydrated -c -d ${SUBDOMAIN}.${HOSTED_ZONE} -t dns-01 -k 'hooks/aws/hook.py'

        # Locate certs and upload to vault
        vault write secret/certs/fullchain.pem value=@certs/${SUBDOMAIN}.${HOSTED_ZONE}/fullchain.pem
        vault write secret/certs/chain.pem value=@certs/${SUBDOMAIN}.${HOSTED_ZONE}/chain.pem
        vault write secret/certs/privkey.pem value=@certs/${SUBDOMAIN}.${HOSTED_ZONE}/privkey.pem
        vault write secret/certs/cert.pem value=@certs/${SUBDOMAIN}.${HOSTED_ZONE}/cert.pem

    fi
}

# -----------------------------------------------------------
# Main
# -----------------------------------------------------------

main() {

    echo "*****************************************"
    echo "* Booting Dehydrated Container ...*"
    echo "*****************************************"

    # Ensure Vault Up
    wait_for_backend

    register
    renew

    # Begin Renewal Cron
    while true; do

        echo "Sleeping for 7 days, until cron is ready ..."

        sleep 7d
        register
        renew

    done
}

main

