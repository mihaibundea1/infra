#!/bin/bash

# Path to the build configuration file
CONFIG_FILE="build_config.txt"
# Log file path
LOG_FILE="linfra.log"

# Set the repositories and local directories
REPOS=(

)
CLONE_DIR="local_sources"
BUILD_DIR="built_services"


# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to clone repositories with specified branches from the config file
clone_repositories() {
    log "Starting to clone repositories..."
    mkdir -p $CLONE_DIR
    mkdir -p $BUILD_DIR
        
    for REPO in "${REPOS[@]}"; do
        REPO_NAME=$(basename $REPO .git)
        BRANCH_NAME=$(grep -w "$REPO_NAME" "$CONFIG_FILE" | cut -d '=' -f2 | xargs)

        if [ -z "$BRANCH_NAME" ]; then
            log "Branch name for '$REPO_NAME' not found in $CONFIG_FILE. Skipping clone."
            continue
        fi

        if [ -d "$CLONE_DIR/$REPO_NAME" ]; then
            log "Repository '$REPO_NAME' already exists in '$CLONE_DIR'. Skipping clone."
        else
            git clone -b "$BRANCH_NAME" $REPO $CLONE_DIR/$REPO_NAME >> "$LOG_FILE" 2>&1
            if [ $? -eq 0 ]; then
                log "Successfully cloned '$REPO_NAME' with branch '$BRANCH_NAME' into '$CLONE_DIR'."
            else
                log "Failed to clone '$REPO_NAME' with branch '$BRANCH_NAME'."
                
            fi
        fi
    done
    
    log "Finished cloning repositories."
}

# Function to run Docker Compose using a specific compose file
run_docker_compose_build() {
    local compose_file=$1
    log "Starting Docker Compose build process using $compose_file..."
    docker compose -f $compose_file up --build -d | tee -a "$LOG_FILE"
    if [ $? -eq 0 ]; then
        log "Docker Compose build process initiated successfully."
        docker compose -f docker-compose.build.yaml logs -f >> "$LOG_FILE" 2>&1 &
    else
        log "Docker Compose build process failed to start."
    fi
}

# Function to wait for all Docker containers to finish
wait_for_containers() {
    local compose_file=$1
    log "Waiting for all Docker containers to finish..."
    
    local loading_symbols=('⠏' '⠛' '⠹' '⢸' '⣰' '⣤' '⣆' '⡇')
    local index=0

    # Wait until all containers have exited
    while docker compose -f "$compose_file" ps | grep -q "Up"; do
        printf "\r Waiting... \e[34m%s\e[0m" "${loading_symbols[$index]}"
        index=$(( (index + 1) % ${#loading_symbols[@]} ))
        sleep 0.1
    done

    printf "\r All Docker containers have finished.           \n"
    log "All Docker containers have finished."
}

# Function to check for non-empty build directories and clean up cloned repositories
check_and_cleanup_source() {
    log "Checking for non-empty build directories and cleaning up..."
    for REPO in "${REPOS[@]}"; do
        REPO_NAME=$(basename $REPO .git)
        ARTIFACT_PATH="$BUILD_DIR/$REPO_NAME"
        if [ "$(ls -A $ARTIFACT_PATH)" ]; then
            log "Build directory '$ARTIFACT_PATH' is not empty."
            rm -rf $CLONE_DIR/$REPO_NAME
            if [ $? -eq 0 ]; then
                log "Removed cloned repository '$CLONE_DIR/$REPO_NAME'."
            else
                log "Failed to remove cloned repository '$CLONE_DIR/$REPO_NAME'."
            fi
        else
            log "Build directory '$ARTIFACT_PATH' is empty. No cleanup performed."
        fi
    done
    log "Finished checking and cleanup."

      # Check if $CLONE_DIR has no child folders, and remove it if empty
    if [ -z "$(ls -A $CLONE_DIR)" ]; then
        log "$CLONE_DIR is empty, removing it."
        rmdir $CLONE_DIR
    fi

    
}

# Function to check if there is any file in each service directory
check_files_artefact() {
    local all_files_present=true

    log "Checking for built artefacts..."
     # Iterate over each subdirectory in the services_dir
    for service in "$BUILD_DIR"/*; do
        if [ -d "$service" ]; then
            service_name=$(basename "$service")

            # Check if there are any files in the service directory
            if [ -z "$(ls -A "$service")" ]; then
                echo -e " \e[31m✘ No files found in $service.\e[0m" | tee -a "$LOG_FILE"
                all_files_present=false
            else
                echo -e " \e[32m✔ Files are present in $service.\e[0m" | tee -a "$LOG_FILE"
            fi
        fi
    done

    # If any directory is missing files, exit with an error code
    if [ "$all_files_present" = false ]; then
        echo -e " \e[31m✘ One or more service directories are missing files.\e[0m" | tee -a "$LOG_FILE"
        return 1
    else
        echo -e " \e[32m✔ All service directories contain files.\e[0m" | tee -a "$LOG_FILE"
        return 0
    fi
}

# Function to install Docker on Ubuntu/Debian
install_docker_ubuntu() {
	# Add Docker's official GPG key:
	sudo apt-get update
	sudo apt-get install ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	
	# Add the repository to Apt sources:
	echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
	$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
}

# Function to install Docker on Fedora/Red Hat
install_docker_fedora() {
    log "Installing Docker Engine Community Edition on Fedora/Red Hat..."

    # Update the package index
    sudo dnf -y update

    # Install required packages
    sudo dnf -y install dnf-plugins-core

    # Set up the stable repository
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    # Install the latest version of Docker Engine Community Edition
    sudo dnf -y install docker-ce docker-ce-cli containerd.io

    log "Docker Engine Community Edition has been installed successfully on Fedora/Red Hat."
}

# Function to check and install Docker if necessary
check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        log "Docker is not installed."

        # Detect the OS and install Docker accordingly
        if [ -f /etc/debian_version]; then
            install_docker_ubuntu
        elif [ -f /etc/debian-release ]; then
            install_docker_fedora
        else
            log "Unsupported Linux distribution."
            exit 1
        fi
        
        # Add the current user to the docker group
        sudo usermod -aG docker $USER
        sudo chown -R $USER /var/run/docker.sock
        
        # Start Docker
        sudo systemctl start docker

        # Enable Docker to start on boot
        sudo systemctl enable docker

        # Verify that Docker is installed correctly by running the hello-world image
        sudo docker run hello-world | tee -a "$LOG_FILE"
    else
        log "Docker is already installed."
    fi
}

# Function to check Docker Compose version
check_docker_compose_version() {
    # Get Docker Compose version
    compose_version=$(docker compose version --short 2>/dev/null || docker-compose --version 2>/dev/null)

    if [[ -z "$compose_version" ]]; then
        log "Docker Compose is not installed or not found in PATH."
        exit 1
    fi

    # Extract the numeric version from the output (works for both 'docker-compose' and 'docker compose')
    if [[ $compose_version == *docker-compose* ]]; then
        compose_version=$(docker-compose --version | awk '{print $3}')
    else
        compose_version=$(docker compose version --short)
    fi

    # Split the version number into major, minor, and patch
    major_version=$(echo "$compose_version" | cut -d. -f1)

    # Check if the major version is less than 2
    if [[ "$major_version" -lt 2 ]]; then
        log "Docker Compose version is below 2.0.0. Please update Docker Compose."
        exit 1
    else
        log "Docker Compose version is $compose_version. Proceeding..."
    fi
}

# Function to manage services for build or deploy
manage_services() {
    local mode=$1  # build or deploy
    local command=$2
    local compose_file="docker-compose.$mode.yaml"

    case "$mode" in
        build)
            case "$command" in
                start)
                    [ -f "$LOG_FILE" ] && rm "$LOG_FILE" && log "Removing old logs: $LOG_FILE."
                    log "Starting build process..."
                    check_and_install_docker
                    check_docker_compose_version
                    clone_repositories
                    run_docker_compose_build "$compose_file"
                    wait_for_containers "$compose_file"
                    check_files_artefact
                    log "Build process completed."
                    docker compose -f "$compose_file" down >> "$LOG_FILE" 2>&1
                    check_and_cleanup_source
                    docker rmi $(docker images -q) -f >> "$LOG_FILE" 2>&1
                    docker system prune -f >> "$LOG_FILE" 2>&1
                    log "Build services stopped and cleaned successfully with $compose_file."
                    ;;
                stop|restart|stop_and_clean)
                    log "Invalid command for build: $command"
                    exit 1
                    ;;
                *)
                    log "Invalid command: $command"
                    exit 1
                    ;;
            esac
            ;;
        deploy)
            case "$command" in
                start)
                    log "Starting deploy services with $compose_file."
                    check_and_install_docker
                    check_docker_compose_version
                    docker compose -f "$compose_file" up --build --quiet-pull -d >> "$LOG_FILE" 2>&1
                    log "Deployed services started successfully with $compose_file."
                    ;;
                stop)
                    log "Stopping deploy services with $compose_file."
                    docker compose -f "$compose_file" down >> "$LOG_FILE" 2>&1
                    log "Deployed services stopped successfully with $compose_file."
                    ;;
                restart)
                    log "Restarting deploy services with $compose_file."
                    manage_services "deploy" stop
                    manage_services "deploy" start
                    log "Deployed services restarted successfully with $compose_file."
                    ;;
                stop_and_clean)
                    log "Stopping and cleaning deploy services with $compose_file."
                    docker compose -f "$compose_file" down >> "$LOG_FILE" 2>&1
                    docker rmi $(docker images -q) -f 2>&1 | tee -a "$LOG_FILE"
                    docker system prune -f 2>&1 | tee -a "$LOG_FILE"
                    log "Deployed services stopped and cleaned successfully with $compose_file."
                    ;;
                *)
                    log "Invalid command: $command"
                    exit 1
                    ;;
            esac
            ;;
        *)
            log "Invalid mode: $mode"
            exit 1
            ;;
    esac
}

# Parse command line arguments
case "$1" in
    -build)
        shift
        if [[ "$1" == "start" ]]; then
            manage_services "build" "$1"
        else
            echo "Usage: $0 -build start" | tee -a "$LOG_FILE"
            exit 1
        fi
        ;;
    -deploy)
        shift
        if [[ "$1" == "start" || "$1" == "stop" || "$1" == "restart" || "$1" == "stop_and_clean" ]]; then
            manage_services "deploy" "$1"
        else
            echo "Usage: $0 -deploy {start|stop|restart|stop_and_clean}" | tee -a "$LOG_FILE"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {-build start|-deploy {start|stop|restart|stop_and_clean}}" | tee -a "$LOG_FILE"
        exit 1
        ;;
esac