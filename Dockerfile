FROM niallbyrne/gc2-base
MAINTAINER Niall Byrne <niall@sharedvisionsolutions.com>

# Begin Image Customization

ARG RUNTIME_USER="dehydrated"
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

# Create the runtime user to limit root inside the container
RUN addgroup ${RUNTIME_USER} && \
    adduser -u ${USER_UID} -G ${RUNTIME_USER} ${RUNTIME_USER} -D && \
    mkdir -p /opt/dehydrated

# Install the Codebase and Python Packages
COPY ./docker/dehydrated/bootstrap.sh /opt/dehydrated/bootstrap.sh
RUN pip3 install --no-cache-dir boto
COPY ./docker/dehydrated/hook.py /opt/dehydrated/hooks/aws/hook.py

# Install default content
RUN mkdir -p /opt/entrypoint
ADD ./config/ssl.nginx                          /etc/nginx/conf.d/ssl.conf
ADD ./config/main.nginx                         /etc/nginx/nginx.conf
ADD ./config/enabled/default.nginx              /etc/nginx/sites-enabled/default.conf
ADD ./scripts/bootstrap.sh                      /opt/entrypoint/bootstrap.sh

# Template Configuration
RUN sed -i.bak "s/<<port>>/${PROXY_PORT}/g"     /etc/nginx/sites-enabled/default.conf
RUN sed -i.bak "s/<<port>>/${PROXY_PORT}/g"     /opt/entrypoint/bootstrap.sh

# Enforce Permissions
RUN chown -R ${RUNTIME_USER}:${RUNTIME_USER} /opt/dehydrated
RUN chown -R ${RUNTIME_USER}:${RUNTIME_USER} /home/${RUNTIME_USER}
USER ${RUNTIME_USER}

WORKDIR /opt/entrypoint
RUN chmod +x /opt/entrypoint/bootstrap.sh
CMD /opt/entrypoint/bootstrap.sh
