#!/bin/bash

# Path to needed files for the script
CONFIG_FILE="build_config.json"
LOG_FILE="landbase_infra.log"
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

    # Parse the config file and loop over each service
    services=$(jq -c '.services[]' "$CONFIG_FILE")
        
    for service in $services; do
        # Extract service details
        service_name=$(echo "$service" | jq -r '.name')
        repo_name=$(echo "$service" | jq -r '.repo_name')
        branch=$(echo "$service" | jq -r '.branch')
        availability=$(echo "$service" | jq -r '.availability')

      if [ "$availability" = true ]; then
            if [ -d "$CLONE_DIR/$service_name" ]; then
                log "Repository '$repo_name' for service '$service_name' already exists in '$CLONE_DIR'. Skipping clone."
            else
                git clone -b "$branch" $repo_name "$CLONE_DIR/$service_name" >> "$LOG_FILE" 2>&1
                if [ $? -eq 0 ]; then
                    log "Successfully cloned '$repo_name' with branch '$branch' into '$CLONE_DIR/$service_name'."
                else
                    log "Failed to clone '$repo_name' with branch '$branch'."
                fi
            fi
        else
            log "Service '$service_name' is marked as unavailable. Skipping clone."
        fi
    done
    
    log "Finished cloning repositories."
}

# Function to run docker-compose for enabled services
run_docker_compose_build() {
    local compose_file=$1
    log "Starting Docker Compose build process using $compose_file..."

    # Start building the list of enabled services
    AVAILABLE_SERVICES=""
    
    # Check if the compose file is docker-compose.deploy.yaml, then add maria-db service
    if [[ "$compose_file" == "docker-compose.deploy.yaml" ]]; then
        log "Adding maria-db service to available services."
        AVAILABLE_SERVICES+="maria-db "
    fi

    # Parse the config file and loop over each service
    services=$(jq -c '.services[]' "$CONFIG_FILE")

    for service in $services; do
        # Extract service details
        service_name=$(echo "$service" | jq -r '.name')
        availability=$(echo "$service" | jq -r '.availability')

        # Only include the service if availability is true
        if [ "$availability" = true ]; then
            log "Service '$service_name' is enabled, added for build."
            AVAILABLE_SERVICES+="${service_name} "
        else
            log "Service '$service_name' is not enabled, skipping."
        fi
    done

    # If there are any enabled services, run docker-compose up
    if [ -n "$AVAILABLE_SERVICES" ]; then
        log "Building enabled services: $AVAILABLE_SERVICES"
        docker compose -f "$compose_file" up -d $AVAILABLE_SERVICES >> "$LOG_FILE" | tee -a "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            log "Build started successfully, following logs..."
            docker compose -f "$compose_file" logs -f $AVAILABLE_SERVICES >> "$LOG_FILE" 2>&1 &
        else
            log "Failed to build services."
        fi
    else
        log "No services enabled to start."
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
    # Parse the config file and loop over each service
    services=$(jq -c '.services[]' "$CONFIG_FILE")

    for service in $services; do
        # Extract service name and availability from the JSON file
        service_name=$(echo "$service" | jq -r '.name')
        availability=$(echo "$service" | jq -r '.availability')

        ARTIFACT_PATH="$BUILD_DIR/$service_name"

        # Only check and remove files if the service is enabled
        if [ "$availability" = true ]; then
            if [ -d "$ARTIFACT_PATH" ] && [ "$(ls -A $ARTIFACT_PATH)" ]; then
                log "Build directory '$ARTIFACT_PATH' is not empty. Removing..."
                rm -rf "$CLONE_DIR/$service_name"
                log "Successfully removed '$CLONE_DIR/$service_name'."
            else
                log "Build directory '$ARTIFACT_PATH' is empty or does not exist."
            fi
        else
            log "Service '$service_name' is disabled, skipping cleanup."
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

# Function to check Docker Compose version
check_docker_compose_version() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log "Error: Docker is not installed."
        log "Please install Docker Engine before running this script."
        exit 1
    fi

    # Check if the integrated Docker Compose is available
    if ! docker compose version &> /dev/null; then
        log "Error: Docker Compose v2+ (integrated with Docker) is not installed."
        log "Please upgrade to Docker Engine v2+ which includes Docker Compose as part of the Docker CLI."
        exit 1
    fi

    # Get Docker Compose version
    compose_version=$(docker compose version --short | cut -d'.' -f1)

    # Ensure Docker Compose is v2+
    if [ "$compose_version" -lt 2 ]; then
        log "Error: Docker Compose version must be v2+."
        log "You are running Docker Compose version $(docker compose version --short)."
        exit 1
    fi

    log "Docker Compose version is $compose_version. Proceeding..."
}

# Function to generate the docker-compose.build.yaml file dynamically
generate_dc_build() {
    DOCKER_COMPOSE_FILE="docker-compose.build.yaml"
    [ -f "$DOCKER_COMPOSE_FILE" ] && rm "$DOCKER_COMPOSE_FILE" && log "Removing old build file: $DOCKER_COMPOSE_FILE."
    echo "services:" >> $DOCKER_COMPOSE_FILE
    services=$(jq -c '.services[]' "$CONFIG_FILE")

    for service in $services; do
        service_name=$(echo "$service" | jq -r '.name')
        state=$(echo "$service" | jq -r '.state')
        availability=$(echo "$service" | jq -r '.availability')
        build_file=$(echo "$service" | jq -r '.build_file')
        binary_file=$(echo "$service" | jq -r '.binary_file')

        if [ "$availability" = true ]; then
            echo "  ${service_name}:" >> $DOCKER_COMPOSE_FILE
            echo "    image: fedora:40" >> $DOCKER_COMPOSE_FILE
            echo "    volumes:" >> $DOCKER_COMPOSE_FILE
            echo "      - ./local_sources/${service_name}:/app" >> $DOCKER_COMPOSE_FILE
            echo "      - ./built_services/${service_name}:/app/${service_name}_output/artefact" >> $DOCKER_COMPOSE_FILE
            #    # Add resource limits for CPU and memory
            # echo "    deploy:" >> $DOCKER_COMPOSE_FILE
            # echo "      resources:" >> $DOCKER_COMPOSE_FILE
            # echo "        limits:" >> $DOCKER_COMPOSE_FILE
            # echo "          cpus: '1.5'" >> $DOCKER_COMPOSE_FILE
            # echo "          memory: 2g" >> $DOCKER_COMPOSE_FILE
            echo "    working_dir: /app" >> $DOCKER_COMPOSE_FILE
            echo "    command: >" >> $DOCKER_COMPOSE_FILE
            echo "      /bin/sh -c \"" >> $DOCKER_COMPOSE_FILE
            echo "      dnf -y update &&" >> $DOCKER_COMPOSE_FILE
            echo "      dnf -y install qt6-qtbase qt6-qtbase-mysql qt6-qtbase-devel gcc g++ make &&" >> $DOCKER_COMPOSE_FILE
            echo "      dnf clean all &&" >> $DOCKER_COMPOSE_FILE
            echo "      mkdir -p /app/${service_name}_output &&" >> $DOCKER_COMPOSE_FILE
            echo "      cd ${service_name}_output &&" >> $DOCKER_COMPOSE_FILE
            if [ "$state" = "debug" ]; then
            echo "      /usr/lib64/qt6/bin/qmake ../${build_file} CONFIG+=debug CONFIG+=qml_debug &&" >> $DOCKER_COMPOSE_FILE
            else
            echo "      /usr/lib64/qt6/bin/qmake ../${build_file} &&" >> $DOCKER_COMPOSE_FILE    
            fi
            echo "      make -j\$(nproc) &&" >> $DOCKER_COMPOSE_FILE
            echo "      cp ${binary_file} /app/${service_name}_output/artefact &&" >> $DOCKER_COMPOSE_FILE
            echo "      chmod -R 777 /app/${service_name}_output\"" >> $DOCKER_COMPOSE_FILE
        fi
    done

    log "docker-compose.build.yaml generated successfully based on ${CONFIG_FILE} details."
}

check_jq_installed() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log "Error: jq is not installed."

        if [ -f /etc/os-release ]; then
            . /etc/os-release
            
            if [[ "$ID" == "ubuntu" ]]; then
                log "You are using Ubuntu. Please install jq by running:"
                log "sudo apt update && sudo apt install -y jq"
            elif [[ "$ID" == "fedora" ]]; then
                log "You are using Fedora. Please install jq by running:"
                log "sudo dnf install -y jq"
            else
                log "Unsupported OS. Please install jq manually."
            fi
        else
            log "Unable to detect OS. Please install jq manually."
        fi
        exit 1
    fi
}

# Function to manage services for build or deploy
manage_services() {
    local mode=$1  # build or deploy
    local command=$2
    local compose_file="docker-compose.$mode.yaml"
    check_jq_installed
    check_docker_compose_version

    case "$mode" in
        build)
            case "$command" in
                start)
                    [ -f "$LOG_FILE" ] && rm "$LOG_FILE" && log "Removing old logs: $LOG_FILE."
                    log "Starting build process..."
                    generate_dc_build
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
                    run_docker_compose_build "$compose_file"
                    # docker compose -f "$compose_file" up --build --quiet-pull -d >> "$LOG_FILE" 2>&1
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