# Stage 1: Builder stage
FROM ubuntu:22.04 AS builder

# Install packages and setup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openssh-server \
    apache2 \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Runtime image
FROM ubuntu:22.04

# Copy necessary files from builder
COPY --from=builder /usr/sbin/sshd /usr/sbin/sshd
COPY --from=builder /usr/sbin/apache2 /usr/sbin/apache2
COPY --from=builder /bin/bash /bin/bash

# Create data directory for persistent storage
RUN mkdir -p /data && chmod 777 /data

# Create entrypoint script with multiple modes
RUN echo '#!/bin/bash\n\
if [ "$1" = "shell" ]; then\n\
    exec /bin/bash\n\
else\n\
    # Start services\n\
    service ssh start\n\
    service apache2 start\n\
    # Keep container running\n\
    tail -f /dev/null\n\
fi' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Expose ports
EXPOSE 22 80

# Declare volume
VOLUME /data

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default command (can override with "shell" for direct access)
CMD ["default"]
