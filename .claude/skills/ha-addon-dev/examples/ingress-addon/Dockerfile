ARG BUILD_FROM
FROM $BUILD_FROM

# Install nginx for web serving
RUN apk add --no-cache nginx

# Create nginx run directory
RUN mkdir -p /run/nginx

# Copy nginx configuration
COPY ingress.conf /etc/nginx/http.d/

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
