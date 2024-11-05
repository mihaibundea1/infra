FROM redis:latest

# Add custom Redis configuration
COPY ./redis/redis.conf /usr/local/etc/redis/redis.conf

# Create data directory
RUN mkdir -p /data && chown redis:redis /data

# Set permissions
RUN chmod 777 /data

# Set memory limit to 1GB
ENV REDIS_MAXMEMORY=1gb
ENV REDIS_MAXMEMORY_POLICY=allkeys-lru

# Define volume mount point
VOLUME ["/data"]

# Set the default command to run Redis with our custom config
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]

# Expose Redis port
EXPOSE 6379

# Set health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD redis-cli ping || exit 1