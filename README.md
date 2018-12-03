# nginx-certified

Latest Master Build<br>
[![CircleCI](https://circleci.com/gh/niall-byrne/nginx-certified/tree/master.svg?style=svg)](https://circleci.com/gh/niall-byrne/goog-playcounts/tree/master)

<br>

A kubernetes friendly ssl enabled nginx reverse proxy, with configurable, auto-renewing let's encrypt certificates. 
Uses [Dehydrated](https://github.com/lukas2511/dehydrated) Under the Covers as a [Let's Encrypt](https://letsencrypt.org/) Client

# Configuration

Configure the following environment variables for you container:

```bash
SUBDOMAIN=test
HOSTED_ZONE=niallbyrne.ca
PRODUCTION=0
DNS_EMAIL=niall@niallbyrne.ca
AWS_ACCESS_KEY_ID=some_secret_value
AWS_SECRET_ACCESS_KEY=some_really_secret_value
```

This can be done with an env var, or with kubernetes secrets.

```bash
kubectl create secret generic aws --from-literal=access_key=REDACTED --from-literal=secret_key=REDACTED
```

```yaml
env:
- name: "SUBDOMAIN"
  value: "playcounts1"
- name: "HOSTED_ZONE"
  value: "niallbyrne.ca"
- name: "DNS_EMAIL"
  value: "niall@niallbyrne.ca"
- name: "PRODUCTION"
  value: "1"
- name: "TERM"
  value: "xterm"
- name: "AWS_ACCESS_KEY_ID"
  valueFrom:
    secretKeyRef:
      name: aws
      key: access_key
- name: "AWS_SECRET_ACCESS_KEY"
    valueFrom:
      secretKeyRef:
        name: aws
        key: secret_key
```




# Notes:

- Setting PRODUCTION to 0 will use the Let's Encrypt Staging endpoint for testing.
- The suggested policy for the AWS Credentials is: ```AmazonRoute53FullAccess```
- You can use any port you like for the reverse proxy component. 

Store the configuration files you wish to deploy in your vault instance, and configure your override.sh file to load them at run time.
(See example deployment.)

# Deployment

The container deviates from typical container best practices by launching both the nginx process, and a simple helper process that ensures the certificates are renewed and written, and nginx is reloaded when required to keep SSL functioning.


