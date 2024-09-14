# Using Docker Compose in Windows PowerShell

# Quick Commands

Here are some useful commands for managing your Docker MariaDB setup:

1. **Start the MariaDB container**:
   ```
   docker-compose -f docker-compose.deploy.yaml up -d
   ```
   This command starts the MariaDB container in detached mode.

2. **Connect to the MariaDB database**:
   ```
   docker exec -it maria-db mariadb -uroot -ppass1234
   ```
   This command opens a MariaDB shell inside the container.

3. **Remove the data directory** (Use with caution! This will delete all your data):
   ```
   rm -r .\data\
   ```
   On Windows PowerShell, use:
   ```
   Remove-Item -Recurse -Force .\data\
   ```
   This command removes the data directory, effectively resetting your database.

4. **Stop and remove the MariaDB container**:
   ```
   docker-compose -f docker-compose.deploy.yaml down
   ```
   This command stops and removes the container, networks, and volumes defined in the docker-compose file.

**Note**: Be very careful when using commands that delete data or remove containers. Always ensure you have backups of important data before performing these operations.

## Correct Usage

1. **Open PowerShell**: Ensure you're in the directory containing your Docker Compose file.

2. **Check Docker Compose Installation**: First, verify that Docker Compose is installed:
   ```powershell
   docker-compose --version
   ```

3. **Run Docker Compose**: Use the following command to start your services:
   ```powershell
   docker-compose -f docker-compose.deploy.yaml up -d
   ```
   - `-f` specifies the file to use (if it's not named `docker-compose.yml`)
   - `up` creates and starts the containers
   - `-d` runs in detached mode (in the background)

4. **Check Running Containers**: To see if your containers are running:
   ```powershell
   docker ps
   ```

5. **Stop and Remove Containers**: When you're done, you can stop and remove the containers:
   ```powershell
   docker-compose -f docker-compose.deploy.yaml down
   ```
   
   ##Connect to the database
   ```powershell
   docker exec -it maria-db mariadb -uroot -ppass1234
   ```
   
   ##Connect locally to the database	
	```powershell
	mysql -h 127.0.0.1 -P 3308 -u root -ppass1234
	```

## Troubleshooting

- **Docker Desktop Running**: Ensure Docker Desktop is running on your Windows machine.
- **File Path**: Make sure you're in the correct directory. Use `Get-Location` to check your current directory.
- **File Permissions**: Ensure you have read permissions for the Docker Compose file.
- **Admin Rights**: The message about "running as Admin in user setup" suggests you might be running PowerShell as an administrator. While this isn't necessarily a problem, it's generally not required for Docker operations unless you're doing something that specifically needs elevated privileges.

## Notes

- The error "code: 0, signal: unknown" typically appears when trying to execute a non-executable file. It's not related to Docker Compose itself.
- If you're new to Docker Compose, remember that it's a tool for defining and running multi-container Docker applications. The YAML file defines the services, networks, and volumes for your application.

If you continue to have issues, please provide more details about what you're trying to achieve with your Docker Compose setup, and I'll be happy to assist further.

# Docker MariaDB Setup

This README provides instructions for setting up a MariaDB database using Docker on Windows, including the necessary steps to install Docker, run the Dockerfile, and interact with the database.

## Table of Contents
1. [Installing Docker on Windows](#installing-docker-on-windows)
2. [Running the Dockerfile](#running-the-dockerfile)
3. [Connecting to the Database](#connecting-to-the-database)
4. [Creating and Populating the Exercises Table](#creating-and-populating-the-exercises-table)
5. [Troubleshooting](#troubleshooting)

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