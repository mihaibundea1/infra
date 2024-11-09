services:
  maria-db:
    image: mariadb
    volumes:
      - ./data:/var/lib/mysql
      - ./initscripts:/docker-entrypoint-initdb.d
    container_name: maria-db
    restart: unless-stopped
    tty: true
    ports:
      - 3308:3306
    environment:
      MARIADB_ROOT_PASSWORD: pass1234
    healthcheck:
      test: ["CMD", "/usr/local/bin/healthcheck.sh", "--connect"]
      start_period: 5s
      interval: 5s
      timeout: 5s
      retries: 10
    networks:
      provedb:
        ipv4_address: 10.10.0.2

  redis:
    image: redis
    container_name: redis
    command: redis-server --maxmemory 1gb --maxmemory-policy allkeys-lru
    ports:
      - 6379:6379
    restart: unless-stopped
    networks:
      provedb:
        ipv4_address: 10.10.0.3

  rabbitmq:
    image: rabbitmq:3-management
    container_name: rabbitmq
    ports:
      - 5672:5672   # AMQP protocol
      - 15672:15672 # Management interface
    restart: unless-stopped
    networks:
      provedb:
        ipv4_address: 10.10.0.4

networks:
  provedb:
    driver: bridge
    ipam:
      config:
        - subnet: 10.10.0.0/16
          gateway: 10.10.0.1