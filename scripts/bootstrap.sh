#!/usr/bin/env bash

mkdir -p /var/cache/letsencrypt

cd /opt/leproxy

leproxy -addr :30000 -http :30001 -hsts -email niall@niallbyrne.ca
