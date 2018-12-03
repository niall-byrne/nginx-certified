# nginx-certified

A kubernetes friendly ssl enabled nginx reverse proxy, with configurable, auto-renewing let's encrypt certificates. 
Uses [Dehydrated](https://github.com/lukas2511/dehydrated) Under the Covers as a [Let's Encrypt](https://letsencrypt.org/) Client

# Configuration

Configure the following environment variables for you container:

```bash
SUBDOMAIN="www"
HOSTED_ZONE="example.com"
DNS_EMAIL="admin@example.com"
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
PRODUCTION=1
PORT=8000
```

# Notes:

- Setting PRODUCTION to 0 will use the Let's Encrypt Staging endpoint for testing.
- The suggested policy for the AWS Credentials is: ```AmazonRoute53FullAccess```
- You can use any port you like for the reverse proxy component. 

Store the configuration files you wish to deploy in your vault instance, and configure your override.sh file to load them at run time.
(See example deployment.)

# Deployment

The container deviates from typical container best practices by launching both the nginx process, and a simple helper process that ensures the certificates are renewed and written, and nginx is reloaded when required to keep SSL functioning.


