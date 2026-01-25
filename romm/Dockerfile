ARG BUILD_FROM
FROM rommapp/romm:latest

# Install bashio for Home Assistant integration
RUN apk add --no-cache \
    bash \
    jq \
    curl \
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v0.16.2.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio*

# Copy rootfs (startup script)
COPY rootfs /

# Set permissions on run script
RUN chmod a+x /run.sh

# Set working directory
WORKDIR /romm

# Expose port (for ingress)
EXPOSE 8095

# Use our custom entrypoint
CMD ["/run.sh"]
