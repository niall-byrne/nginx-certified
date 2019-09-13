FROM alpine:3.9
MAINTAINER Niall Byrne <niall@niallbyrne.ca>

ARG DEHYDRATED_VERSION="v0.6.5"

# Set locale
ENV LANG US.UTF-8

# Install Packages and Application
    RUN apk add --no-cache                                  \
        bash                                                \
        curl                                                \
        git                                                 \
        nginx                                               \
        openssl                                             \
        python3                                             \
    && pip3 install -U pip                                  \
    && pip3 install -U setuptools wheel                     \
    && ln -sf /usr/bin/python3 /usr/bin/python              \
    && mkdir -p /opt                                        \
    && cd /opt                                              \
    && git clone https://github.com/lukas2511/dehydrated    \
    && mkdir -p dehydrated/certs                            \
    && cd dehydrated                                        \
    && git checkout -b work tags/${DEHYDRATED_VERSION}      \
    && mkdir -p hooks/aws                                   \
    && apk del                                              \
       git                                                  \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/             \
    && mkdir -p /opt/entrypoint                             \
    && mkdir -p /var/tmp/nginx

# Install Dehydrated Hook for AWS Route 53
COPY ./dehydrated/hook.py               /opt/dehydrated/hooks/aws/hook.py
RUN pip3 install --no-cache-dir boto

# Install default content
ADD ./nginx/ssl.nginx                   /etc/nginx/conf.d/ssl.conf
ADD ./nginx/main.nginx                  /etc/nginx/nginx.conf
ADD ./nginx/enabled/default.nginx       /etc/nginx/sites-enabled/default.conf

# Add Bootstrap Script
ADD ./bootstrap.sh                      /opt/dehydrated/bootstrap.sh

# Execute Permissions
RUN chmod +x /opt/dehydrated/bootstrap.sh

WORKDIR /opt/dehydrated
CMD /opt/dehydrated/bootstrap.sh
