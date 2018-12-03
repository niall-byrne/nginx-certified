FROM niallbyrne/gc2-base
MAINTAINER Niall Byrne <niall@sharedvisionsolutions.com>

# Begin Image Customization

ARG DEHYDRATED_VERSION="v0.6.2"
ARG USER_UID="501"
ARG PROXY_PORT="8000"

# Set locale
ENV LANG US.UTF-8

RUN apk add --no-cache \
    git \
    nginx \
    openssl && \
    mkdir -p /opt && \
    cd /opt && \
    git clone https://github.com/lukas2511/dehydrated && \
    mkdir -p dehydrated/certs && \
    cd dehydrated && \
    git checkout -b work tags/${DEHYDRATED_VERSION} && \
    mkdir -p hooks/aws && \
    apk del git && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/

RUN    mkdir -p /opt/dehydrated

# Install Dehydrated Hook for AWS Route 53
COPY ./dehydrated/hook.py                       /opt/dehydrated/hooks/aws/hook.py
RUN pip3 install --no-cache-dir boto

# Install default content
RUN mkdir -p /opt/entrypoint && \
    mkdir -p /var/tmp/nginx
ADD ./nginx/ssl.nginx                           /etc/nginx/conf.d/ssl.conf
ADD ./nginx/main.nginx                          /etc/nginx/nginx.conf
ADD ./nginx/enabled/default.nginx               /etc/nginx/sites-enabled/default.conf

# Add Bootstrap Script
ADD ./bootstrap.sh                              /opt/dehydrated/bootstrap.sh

WORKDIR /opt/entrypoint
RUN chmod +x /opt/dehydrated/bootstrap.sh
CMD /opt/dehydrated/bootstrap.sh
