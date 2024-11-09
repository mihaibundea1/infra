FROM rabbitmq:3-management

# Add custom configurations
COPY ./rabbitmq/rabbitmq.conf /etc/rabbitmq/
COPY ./rabbitmq/definitions.json /etc/rabbitmq/

# Enable needed plugins
RUN rabbitmq-plugins enable --offline \
    rabbitmq_management \
    rabbitmq_prometheus \
    rabbitmq_mqtt

# Set default user and password
ENV RABBITMQ_DEFAULT_USER=guest
ENV RABBITMQ_DEFAULT_PASS=guest

# Create directories and set permissions
RUN mkdir -p /var/lib/rabbitmq/mnesia && \
    chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

# Define volume mount points
VOLUME ["/var/lib/rabbitmq", "/var/log/rabbitmq"]

# Expose RabbitMQ ports
EXPOSE 5672 15672

# Set health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD rabbitmq-diagnostics check_port_connectivity || exit 1