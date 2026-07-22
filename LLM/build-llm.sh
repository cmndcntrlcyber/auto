#!/bin/bash

# Private LLM Setup Script
# This script sets up a private LLM environment with NVIDIA GPU support

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

# Function to clean up temporary files
cleanup() {
    log "Cleaning up temporary files..."
    rm -f cuda-ubuntu*.pin cuda-repo-*.deb
    log "Cleanup complete."
}

# Function to check system requirements
check_system_requirements() {
    log "Checking system requirements..."
    
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root"
    fi
    
    # Check if system has NVIDIA GPU
    if ! lspci | grep -i nvidia &> /dev/null; then
        warning "No NVIDIA GPU detected. This setup is intended for systems with NVIDIA GPUs."
        read -p "Do you want to continue anyway? (y/n): " -r continue_without_gpu
        if [[ ! "$continue_without_gpu" =~ ^[Yy]$ ]]; then
            error "Setup aborted. Please run this script on a system with an NVIDIA GPU."
        fi
    fi
    
    # Check Ubuntu version
    if ! grep -q "Ubuntu 22.04" /etc/os-release; then
        warning "This script is optimized for Ubuntu 22.04."
        read -p "Do you want to continue anyway? (y/n): " -r continue_other_os
        if [[ ! "$continue_other_os" =~ ^[Yy]$ ]]; then
            error "Setup aborted. Please run this script on Ubuntu 22.04."
        fi
    fi
    
    # Check if Docker is installed
    if ! check_command "docker"; then
        warning "Docker is not installed. It will be installed during the setup process."
    else
        log "Docker is already installed."
    fi
    
    log "System requirements check completed."
}

# Function to install NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
    log "Installing NVIDIA Container Toolkit..."
    
    # Add NVIDIA Container Toolkit repository
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    
    if [ $? -ne 0 ]; then
        error "Failed to download NVIDIA GPG key"
    fi
    
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    if [ $? -ne 0 ]; then
        error "Failed to add NVIDIA repository"
    fi
    
    # Update package lists
    log "Updating package lists..."
    apt-get update
    
    if [ $? -ne 0 ]; then
        error "Failed to update package lists"
    fi
    
    # Install NVIDIA Container Toolkit
    log "Installing NVIDIA Container Toolkit package..."
    apt-get install -y nvidia-container-toolkit
    
    if [ $? -ne 0 ]; then
        error "Failed to install NVIDIA Container Toolkit"
    fi
    
    log "NVIDIA Container Toolkit installed successfully."
}

# Function to install CUDA Toolkit
install_cuda_toolkit() {
    log "Installing CUDA Toolkit..."
    
    # Get latest CUDA version for Ubuntu 22.04
    local cuda_version="12.6.2"
    local cuda_build="560.35.03"
    
    # Download CUDA repository pin
    log "Downloading CUDA repository pin..."
    wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
    
    if [ $? -ne 0 ]; then
        error "Failed to download CUDA repository pin"
    fi
    
    # Move pin file to preferences directory
    mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
    
    if [ $? -ne 0 ]; then
        error "Failed to move CUDA repository pin"
    fi
    
    # Download CUDA repository package
    log "Downloading CUDA repository package..."
    local cuda_repo_pkg="cuda-repo-ubuntu2204-12-6-local_${cuda_version}-${cuda_build}-1_amd64.deb"
    wget -q "https://developer.download.nvidia.com/compute/cuda/${cuda_version}/local_installers/${cuda_repo_pkg}"
    
    if [ $? -ne 0 ]; then
        error "Failed to download CUDA repository package"
    fi
    
    # Install CUDA repository package
    log "Installing CUDA repository package..."
    dpkg -i "${cuda_repo_pkg}"
    
    if [ $? -ne 0 ]; then
        error "Failed to install CUDA repository package"
    fi
    
    # Copy CUDA keyring
    cp /var/cuda-repo-ubuntu2204-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/
    
    if [ $? -ne 0 ]; then
        error "Failed to copy CUDA keyring"
    fi
    
    # Update package lists
    log "Updating package lists..."
    apt-get update
    
    if [ $? -ne 0 ]; then
        error "Failed to update package lists"
    fi
    
    # Install CUDA Toolkit
    log "Installing CUDA Toolkit..."
    apt-get -y install cuda-toolkit-12-6
    
    if [ $? -ne 0 ]; then
        error "Failed to install CUDA Toolkit"
    fi
    
    log "CUDA Toolkit installed successfully."
}

# Function to configure Docker for NVIDIA runtime
configure_docker_nvidia_runtime() {
    log "Configuring Docker for NVIDIA runtime..."
    
    # Configure NVIDIA Container Toolkit runtime for Docker
    nvidia-ctk runtime configure --runtime=docker
    
    if [ $? -ne 0 ]; then
        error "Failed to configure NVIDIA runtime for Docker"
    fi
    
    # Restart Docker service
    log "Restarting Docker service..."
    systemctl restart docker
    
    if [ $? -ne 0 ]; then
        error "Failed to restart Docker service"
    fi
    
    log "Docker configured for NVIDIA runtime successfully."
}

# Function to install LLM stack with Docker Compose
install_llm_stack() {
    log "Installing LLM stack with Docker Compose..."
    
    # Create directory for LLM stack
    local llm_dir="/opt/private-llm"
    
    if [ -d "$llm_dir" ]; then
        warning "Directory $llm_dir already exists."
        read -p "Do you want to overwrite the existing configuration? (y/n): " -r overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            error "Setup aborted. Please remove or rename the existing directory and try again."
        fi
    fi
    
    mkdir -p "$llm_dir"
    
    if [ $? -ne 0 ]; then
        error "Failed to create directory $llm_dir"
    fi
    
    # Download Docker Compose file
    log "Downloading Docker Compose file..."
    curl -s "https://raw.githubusercontent.com/cmndcntrlcyber/auto/refs/heads/main/configs/docker/compose%20templates/private-llm.docker-compose.yml" > "$llm_dir/docker-compose.yml"
    
    if [ $? -ne 0 ] || [ ! -s "$llm_dir/docker-compose.yml" ]; then
        error "Failed to download Docker Compose file"
    fi
    
    # Start LLM stack with Docker Compose
    log "Starting LLM stack..."
    cd "$llm_dir" || error "Failed to change to directory $llm_dir"
    
    docker compose up -d
    
    if [ $? -ne 0 ]; then
        error "Failed to start LLM stack"
    fi
    
    log "LLM stack started successfully."
}

# Main script execution starts here
log "Starting Private LLM setup..."

# Check system requirements
check_system_requirements

# Install NVIDIA Container Toolkit
install_nvidia_container_toolkit

# Install CUDA Toolkit
install_cuda_toolkit

# Configure Docker for NVIDIA runtime
configure_docker_nvidia_runtime

# Install LLM stack with Docker Compose
install_llm_stack

# Clean up
cleanup

log "======================================================================"
log "Private LLM environment has been successfully set up!"
log ""
log "LLM stack is running in Docker containers."
log "Configuration directory: /opt/private-llm"
log ""
log "To check the status of the containers:"
log "  docker ps"
log ""
log "To stop the LLM stack:"
log "  cd /opt/private-llm && docker compose down"
log ""
log "To start the LLM stack again:"
log "  cd /opt/private-llm && docker compose up -d"
log ""
log "For more information, check the documentation of the specific LLM components."
log "======================================================================"
