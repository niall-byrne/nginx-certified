# nginx-certified

A kubernetes friendly ssl enabled nginx container, with configurable, auto-renewing let's encrypt certificates. 
Uses Lego () under the covers as an ACME Client to facilitate generation and renewal of certificates.

# Methodology

nginx-certified will create and renew SSL certificates from the [Let's Encrypt](https://letsencrypt.org/) API

# Configuration

Configure the following environment variables for you container:

```bash
DOMAIN="example.com"
EMAIL="admin@example.com"
VAULT_ADDR="http://127.0.0.1:8200"
VAULT_TOKEN="8118185b-0ec3-42ad-9f3d-cda4c76f4024"
PRODUCTION=1
```

Store the configuration files you wish to deploy in your vault instance, and configure your override.sh file to load them at run time.
(See example deployment.)

# Deployment

