#!/bin/bash

# -----------------------------------------------------------
# nginx-certified - An automated Let's Encrypt integrated reverse proxy
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

[[ -z ${DNS_EMAIL} ]] && error DNS_EMAIL
[[ -z ${SUBDOMAIN} ]] && error SUBDOMAIN
[[ -z ${HOSTED_ZONE} ]] && error HOSTED_ZONE
[[ -z ${AWS_ACCESS_KEY_ID} ]] && error AWS_ACCESS_KEY_ID
[[ -z ${AWS_SECRET_ACCESS_KEY} ]] && error AWS_SECRET_ACCESS_KEY

MAX_RETRIES=4

PRODUCTION_ENVIRONMENT=${PRODUCTION:-0}
PORT="${PROXY_PORT:-8000}"

[[ ${PRODUCTION_ENVIRONMENT} -eq 0 ]] && DEHYDRATED_CA="https://acme-staging-v02.api.letsencrypt.org/directory"
[[ ${PRODUCTION_ENVIRONMENT} -eq 1 ]] && DEHYDRATED_CA="https://acme-v02.api.letsencrypt.org/directory"
sed -i.bak "s/<<port>>/${PORT}/g" /etc/nginx/sites-enabled/default.conf
sed -i.bak "s/<<servername>>/${SUBDOMAIN}.${HOSTED_ZONE}/g" /etc/nginx/sites-enabled/default.conf
rm /etc/nginx/sites-enabled/default.conf.bak

echo "BOOTSTRAP: Let's Encrypt Endpoint set to ${DEHYDRATED_CA} ..."
echo "BOOTSTRAP: Proxying to 127.0.0.1:${PORT} ..."

RETRIES=${MAX_RETRIES}

# -----------------------------------------------------------
# Functions
# -----------------------------------------------------------

wait_for_backend() {
    return
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
    rm -rf /opt/dehydrated/READY

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

        RETRIES=$((RETRIES-1))
        [[ ${RETRIES} -gt 0 ]] && renew
        exit 127

    else

        echo "*****************************************"
        echo "* Calling Let's Encrypt API ...         *"
        echo "*****************************************"

        # Generate Certificates
        cd /opt/dehydrated
        ./dehydrated -c -d ${SUBDOMAIN}.${HOSTED_ZONE} -t dns-01 -k 'hooks/aws/hook.py'

        if [[ ! -f $(pwd)/certs/${SUBDOMAIN}.${HOSTED_ZONE}/fullchain.pem ]]; then
            echo "ERROR: failed to generate certificates."
            RETRIES=$((RETRIES-1))
            [[ ${RETRIES} -gt 0 ]] && renew
            exit 127
        fi

        # Move Certs Into Place
        mkdir -p /etc/pki
        ln -sf $(pwd)/certs/${SUBDOMAIN}.${HOSTED_ZONE}/fullchain.pem       /etc/pki/fullchain.pem
        ln -sf $(pwd)/certs/${SUBDOMAIN}.${HOSTED_ZONE}/privkey.pem         /etc/pki/privkey.key

        # Restart nginx
        [[ -f /var/run/nginx.pid ]] && kill -HUP $(cat /var/run/nginx.pid)

    fi
}

# -----------------------------------------------------------
# Main
# -----------------------------------------------------------

main() {

    echo "*****************************************"
    echo "* Booting Container ...                 *"
    echo "*****************************************"

    # Ensure the Backend is Up
    wait_for_backend

    RETRIES=${MAX_RETRIES}

    register
    renew

    nginx

    # Begin Renewal Cron
    while true; do

        echo "Sleeping for 7 days, until cron is ready ..."

        sleep 7d
        RETRIES=${MAX_RETRIES}
        renew

    done
}

main

