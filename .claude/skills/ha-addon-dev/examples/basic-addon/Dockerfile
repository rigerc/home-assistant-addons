ARG BUILD_FROM
FROM $BUILD_FROM

# Install Python 3 for simple HTTP server
RUN apk add --no-cache python3

# Set working directory to share for serving files
WORKDIR /share

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
