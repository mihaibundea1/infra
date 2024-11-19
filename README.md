# Docker MariaDB Setup

This README provides instructions for setting up a MariaDB database using Docker on Windows, including the necessary steps to install Docker, run the Dockerfile, and interact with the database.

## Table of Contents
1. [Installing Docker on Windows](#installing-docker-on-windows)
2. [Running the Dockerfile](#running-the-dockerfile)
3. [Connecting to the Database](#connecting-to-the-database)
4. [Creating and Populating the Exercises Table](#creating-and-populating-the-exercises-table)
5. [Redis Commands](#redis-commands)
6. [Troubleshooting](#troubleshooting)

## Installing Docker on Windows

1. **System Requirements**:
   - Windows 10 64-bit: Pro, Enterprise, or Education (Build 16299 or later).
   - Hyper-V and Containers Windows features must be enabled.

2. **Download Docker Desktop**:
   - Go to [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
   - Click on "Get Docker" to download the installer.

3. **Install Docker Desktop**:
   - Run the installer and follow the prompts.
   - During installation, ensure the "Use WSL 2 instead of Hyper-V" option is selected if available.

4. **Start Docker Desktop**:
   - Once installed, start Docker Desktop from the Windows Start menu.
   - Wait for Docker to start (the whale icon in the taskbar will stop animating).

5. **Verify Installation**:
   - Open PowerShell and run:
     ```
     docker --version
     ```
   - If you see the Docker version, the installation was successful.

## Running the Dockerfile

1. **Prepare the Docker Compose File**:
   - Create a file named `docker-compose.deploy.yaml` in your project directory.
   - Add the following content:

     ```yaml
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
           dmsdb:
             ipv4_address: 10.10.0.2
     networks:
       dmsdb:
         driver: bridge
         ipam: 
           config:
             - subnet: 10.10.0.0/16
               gateway: 10.10.0.1
     ```

2. **Start the Container**:
   - Open PowerShell in your project directory.
   - Run the following command:
     ```
     docker-compose -f docker-compose.deploy.yaml up -d
     ```

3. **Verify the Container is Running**:
   ```
   docker ps
   ```
   You should see the `maria-db` container in the list.

## Connecting to the Database

1. **Using Docker CLI**:
   ```
   docker exec -it maria-db mariadb -uroot -ppass1234
   ```

2. **Using a MySQL Client on Host Machine**:
   - Host: `localhost` or `127.0.0.1`
   - Port: `3308`
   - Username: `root`
   - Password: `pass1234`

3. **Connect locally to the database**:
   ```powershell
   mysql -h 127.0.0.1 -P 3308 -u root -ppass1234
   ```

## Redis Commands

1. **Connect to Redis CLI**:
   ```
   docker exec -it redis-cache redis-cli -a "redis1234"
   ```

2. **Get all exercises**:
   ```
   GET "exercises:all"
   ```

3. **Delete all exercises**:
   ```
   DEL "exercises:all"
   ```

## Creating and Populating the Exercises Table

Once connected to the database, run the following SQL commands:

```sql
CREATE DATABASE IF NOT EXISTS fitness_app;
USE fitness_app;

CREATE TABLE exercises (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    video_cdn_url VARCHAR(255),
    image_cdn_url VARCHAR(255)
);

INSERT INTO exercises (name, video_cdn_url, image_cdn_url) VALUES
    ('Push-ups', 'https://your-cdn.com/videos/pushups.mp4', 'https://your-cdn.com/images/pushups.jpg'),
    ('Squats', 'https://your-cdn.com/videos/squats.mp4', 'https://your-cdn.com/images/squats.jpg'),
    ('Lunges', 'https://your-cdn.com/videos/lunges.mp4', 'https://your-cdn.com/images/lunges.jpg'),
    ('Plank', 'https://your-cdn.com/videos/plank.mp4', 'https://your-cdn.com/images/plank.jpg'),
    ('Burpees', 'https://your-cdn.com/videos/burpees.mp4', 'https://your-cdn.com/images/burpees.jpg'),
    ('Mountain Climbers', 'https://your-cdn.com/videos/mountain_climbers.mp4', 'https://your-cdn.com/images/mountain_climbers.jpg'),
    ('Jumping Jacks', 'https://your-cdn.com/videos/jumping_jacks.mp4', 'https://your-cdn.com/images/jumping_jacks.jpg'),
    ('Sit-ups', 'https://your-cdn.com/videos/situps.mp4', 'https://your-cdn.com/images/situps.jpg'),
    ('Bicycle Crunches', 'https://your-cdn.com/videos/bicycle_crunches.mp4', 'https://your-cdn.com/images/bicycle_crunches.jpg'),
    ('Russian Twists', 'https://your-cdn.com/videos/russian_twists.mp4', 'https://your-cdn.com/images/russian_twists.jpg');
```

Replace `'https://your-cdn.com/'` with your actual CDN URL.

## Troubleshooting

- If you can't connect to the database, ensure the container is running:
  ```
  docker ps
  ```
- Check container logs for any errors:
  ```
  docker logs maria-db
  ```
- If you need to rebuild the container:
  ```
  docker-compose -f docker-compose.deploy.yaml down
  docker-compose -f docker-compose.deploy.yaml up -d --build
  ```

For more detailed troubleshooting, refer to the Docker documentation or seek assistance in Docker community forums.