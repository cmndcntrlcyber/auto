#!/bin/bash

# Mythic (Merlin) C2 Framework Setup Script
# This script sets up the Mythic Command and Control (C2) framework

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function for logging
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# Function to check and install dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    # List of required commands
    local dependencies=("git" "docker" "docker-compose")
    
    for cmd in "${dependencies[@]}"; do
        if ! check_command "$cmd"; then
            warning "$cmd is not installed. Attempting to install..."
            
            if [ "$cmd" = "git" ]; then
                if ! apt-get update && apt-get install -y git; then
                    error "Failed to install git. Please install it manually."
                fi
            elif [ "$cmd" = "docker" ]; then
                warning "Docker is not installed. Please install Docker manually."
                warning "Visit https://docs.docker.com/engine/install/ for installation instructions."
                error "Docker is required for Mythic. Please install it and try again."
            elif [ "$cmd" = "docker-compose" ]; then
                warning "Docker Compose is not installed. Please install Docker Compose manually."
                warning "Visit https://docs.docker.com/compose/install/ for installation instructions."
                error "Docker Compose is required for Mythic. Please install it and try again."
            fi
        fi
    done
    
    log "All dependencies are installed."
}

# Main script execution starts here
log "Starting Mythic (Merlin) C2 Framework setup..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
fi

# Check dependencies
check_dependencies

# Ask for installation directory
read -p "Enter the directory for Mythic installation (default: /opt/Mythic): " install_dir
install_dir=${install_dir:-/opt/Mythic}

# Check if directory already exists
if [ -d "$install_dir" ]; then
    warning "Directory $install_dir already exists."
    read -p "Do you want to remove the existing directory and continue? (y/n): " -r overwrite
    if [[ "$overwrite" =~ ^[Yy]$ ]]; then
        log "Removing existing directory..."
        rm -rf "$install_dir"
    else
        error "Setup aborted. Please choose a different directory or remove the existing one."
    fi
fi

# Create parent directory if needed
parent_dir=$(dirname "$install_dir")
if [ ! -d "$parent_dir" ]; then
    log "Creating parent directory $parent_dir..."
    mkdir -p "$parent_dir"
    
    if [ $? -ne 0 ]; then
        error "Failed to create parent directory $parent_dir"
    fi
fi

# Clone repository
log "Downloading Mythic from GitHub..."
if ! git clone https://github.com/its-a-feature/Mythic.git "$install_dir"; then
    error "Failed to clone Mythic repository"
fi

# Change to installation directory
cd "$install_dir" || error "Failed to change to installation directory"

# Build Mythic
log "Building Mythic..."
if ! sudo make; then
    error "Failed to build Mythic"
fi

# Start Mythic
log "Starting Mythic..."
if ! ./mythic-cli start; then
    error "Failed to start Mythic"
fi

log "======================================================================"
log "Mythic (Merlin) C2 Framework has been successfully set up!"
log ""
log "Installation directory: $install_dir"
log ""
log "To access the Mythic web interface:"
log "  http://localhost:7443"
log ""
log "Default credentials:"
log "  Username: mythic_admin"
log "  Password: mythic_password"
log ""
log "IMPORTANT: Change the default password immediately!"
log ""
log "Mythic CLI commands:"
log "  ./mythic-cli status    - Check the status of Mythic"
log "  ./mythic-cli stop      - Stop Mythic"
log "  ./mythic-cli start     - Start Mythic"
log "  ./mythic-cli restart   - Restart Mythic"
log ""
log "For more information, visit: https://github.com/its-a-feature/Mythic"
log "======================================================================"
