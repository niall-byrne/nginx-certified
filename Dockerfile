FROM alpine:3.8

# Variables
ARG LEPROXY_PROXY="https://github.com/artyom/leproxy/releases/download/20180113/leproxy-linux-amd64.tar.gz"

# Prepare package system
RUN apk update && \
    apk upgrade && \
    apk add \
        bash \
        curl \
        openssl \
        nginx \
        tar && \
    rm -rf /var/cache/apk/* && \
    rm -rf /etc/nginx/conf.d/*

# Install LeProxy
RUN mkdir -p leproxy && \
    cd leproxy && \
    curl -L "${LEPROXY_PROXY}" > proxy.tar.gz && \
    tar xvzf proxy.tar.gz && \
    mv leproxy /usr/bin/leproxy && \
    cd .. && \
    rm -rf leproxy && \
    mkdir -p /opt/leproxy

# Set locale
ENV LANG US.UTF-8

# Add dynamic content directories
RUN mkdir -p /opt/leproxy
RUN mkdir -p /opt/entrypoint
ADD ./scripts/bootstrap.sh /opt/entrypoint/bootstrap.sh
ADD ./scripts/mapping.yml /opt/entrypoint/mapping.yml

WORKDIR /opt/vault

EXPOSE 80
EXPOSE 443

CMD ["/opt/entrypoint/bootstrap.sh"]
