#!/bin/bash

"""
Shared Installation Functions Library

This library provides common installation and setup functions used across
multiple scripts in the security automation toolkit. It includes functions
for Docker installation, Python environment setup, package management,
logging, and error handling.

Author: Security Automation Team
Version: 1.0.0
License: MIT
"""

# Color codes for consistent logging across all scripts
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Global configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/var/log/security-automation.log"

# Logging functions with consistent formatting
log_info() {
    local message="$1"
    echo -e "${GREEN}[INFO]${NC} $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $message" >> "$LOG_FILE" 2>/dev/null || true
}

log_warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $message" >> "$LOG_FILE" 2>/dev/null || true
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $message" >> "$LOG_FILE" 2>/dev/null || true
}

log_step() {
    local message="$1"
    echo -e "${BLUE}[STEP]${NC} $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [STEP] $message" >> "$LOG_FILE" 2>/dev/null || true
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $message" >> "$LOG_FILE" 2>/dev/null || true
}

# Progress tracking functions
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    echo -e "${PURPLE}[${current}/${total}]${NC} $message"
}

# Error handling and cleanup
setup_error_handling() {
    set -e  # Exit on any error
    trap 'handle_error $LINENO $?' ERR
}

handle_error() {
    local line_number="$1"
    local exit_code="$2"
    log_error "Script failed at line $line_number with exit code $exit_code"
    cleanup_on_error
    exit "$exit_code"
}

cleanup_on_error() {
    log_info "Performing cleanup after error..."
    # Add any cleanup operations here
    # This function can be overridden by calling scripts
}

# System requirement checks
check_root_privileges() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons."
        log_info "Please run as a regular user. The script will use sudo when needed."
        return 1
    fi
    return 0
}

check_sudo_privileges() {
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges."
        log_info "Please ensure you can run sudo commands."
        return 1
    fi
    return 0
}

check_internet_connectivity() {
    log_step "Checking internet connectivity..."
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "No internet connection detected. Please check your network."
        return 1
    fi
    log_success "Internet connectivity confirmed"
    return 0
}

check_disk_space() {
    local required_space_gb="$1"
    local required_space_kb=$((required_space_gb * 1024 * 1024))
    
    log_step "Checking available disk space..."
    local available_space=$(df / | awk 'NR==2 {print $4}')
    
    if [[ $available_space -lt $required_space_kb ]]; then
        log_error "Insufficient disk space. At least ${required_space_gb}GB free space required."
        log_error "Available: $((available_space / 1024 / 1024))GB"
        return 1
    fi
    
    log_success "Sufficient disk space available: $((available_space / 1024 / 1024))GB"
    return 0
}

# Command and package management
check_command() {
    local command="$1"
    if command -v "$command" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

install_package() {
    local package="$1"
    local retry_count="${2:-3}"
    
    log_info "Installing package: $package"
    
    for ((i=1; i<=retry_count; i++)); do
        if sudo apt install -y "$package"; then
            log_success "Successfully installed: $package"
            return 0
        else
            log_warn "Failed to install $package (attempt $i/$retry_count)"
            if [[ $i -lt $retry_count ]]; then
                log_info "Retrying in 5 seconds..."
                sleep 5
                sudo apt update
            fi
        fi
    done
    
    log_error "Failed to install $package after $retry_count attempts"
    return 1
}

install_packages() {
    local packages=("$@")
    local failed_packages=()
    
    log_step "Installing packages: ${packages[*]}"
    
    # Update package lists first
    log_info "Updating package lists..."
    sudo apt update
    
    for package in "${packages[@]}"; do
        if ! install_package "$package"; then
            failed_packages+=("$package")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warn "Failed to install packages: ${failed_packages[*]}"
        return 1
    fi
    
    log_success "All packages installed successfully"
    return 0
}

# Docker installation function (consolidated from random/install_docker.sh)
install_docker() {
    log_step "Installing Docker and container tools..."
    
    # Remove conflicting packages
    log_info "Removing conflicting Docker packages..."
    local conflicting_packages=(
        "docker.io" "docker-doc" "docker-compose" "docker-compose-v2" 
        "podman-docker" "containerd" "runc"
    )
    
    for pkg in "${conflicting_packages[@]}"; do
        sudo apt remove -y "$pkg" 2>/dev/null || true
    done
    
    # Install prerequisites
    log_info "Installing Docker prerequisites..."
    install_packages "ca-certificates" "curl" "gnupg" "lsb-release"
    
    # Add Docker's official GPG key
    log_info "Adding Docker's official GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add Docker repository
    log_info "Adding Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package list and install Docker
    sudo apt update
    install_packages "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
    
    # Add user to docker group
    log_info "Adding user to docker group..."
    sudo usermod -aG docker "$USER"
    
    # Install docker-compose (standalone)
    log_info "Installing docker-compose standalone..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Start and enable Docker service
    log_info "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    log_success "Docker installation completed"
    log_warn "Note: You may need to log out and back in for Docker group membership to take effect"
    
    return 0
}

# Python environment management
setup_python_environment() {
    local env_name="$1"
    local python_version="${2:-python3}"
    local requirements_file="$3"
    
    log_step "Setting up Python environment: $env_name"
    
    # Check if Python is available
    if ! check_command "$python_version"; then
        log_error "Python ($python_version) is not installed"
        return 1
    fi
    
    # Create virtual environment
    log_info "Creating virtual environment..."
    if ! "$python_version" -m venv "$env_name"; then
        log_error "Failed to create virtual environment"
        return 1
    fi
    
    # Activate virtual environment
    log_info "Activating virtual environment..."
    source "$env_name/bin/activate"
    
    # Upgrade pip
    log_info "Upgrading pip..."
    pip install --upgrade pip
    
    # Install requirements if provided
    if [[ -n "$requirements_file" && -f "$requirements_file" ]]; then
        log_info "Installing requirements from $requirements_file..."
        pip install -r "$requirements_file"
    fi
    
    log_success "Python environment setup completed"
    return 0
}

# File and directory management
create_directory_structure() {
    local directories=("$@")
    
    log_step "Creating directory structure..."
    
    for dir in "${directories[@]}"; do
        if mkdir -p "$dir"; then
            log_info "Created directory: $dir"
        else
            log_error "Failed to create directory: $dir"
            return 1
        fi
    done
    
    log_success "Directory structure created successfully"
    return 0
}

download_file() {
    local url="$1"
    local output_file="$2"
    local retry_count="${3:-3}"
    
    log_info "Downloading: $url"
    
    for ((i=1; i<=retry_count; i++)); do
        if curl -fsSL "$url" -o "$output_file"; then
            log_success "Successfully downloaded: $output_file"
            return 0
        else
            log_warn "Download failed (attempt $i/$retry_count)"
            if [[ $i -lt $retry_count ]]; then
                log_info "Retrying in 3 seconds..."
                sleep 3
            fi
        fi
    done
    
    log_error "Failed to download $url after $retry_count attempts"
    return 1
}

# Git repository management
clone_repository() {
    local repo_url="$1"
    local target_dir="$2"
    local branch="${3:-main}"
    
    log_info "Cloning repository: $repo_url"
    
    if [[ -d "$target_dir" ]]; then
        log_info "Directory $target_dir already exists, updating..."
        cd "$target_dir"
        if git pull origin "$branch"; then
            log_success "Repository updated successfully"
            return 0
        else
            log_warn "Failed to update repository, trying fresh clone..."
            cd ..
            rm -rf "$target_dir"
        fi
    fi
    
    if git clone -b "$branch" "$repo_url" "$target_dir"; then
        log_success "Repository cloned successfully"
        return 0
    else
        log_error "Failed to clone repository: $repo_url"
        return 1
    fi
}

# Service management
manage_service() {
    local action="$1"
    local service="$2"
    
    log_info "${action^}ing service: $service"
    
    case "$action" in
        "start"|"stop"|"restart"|"enable"|"disable")
            if sudo systemctl "$action" "$service"; then
                log_success "Service $service ${action}ed successfully"
                return 0
            else
                log_error "Failed to $action service: $service"
                return 1
            fi
            ;;
        "status")
            sudo systemctl status "$service"
            return $?
            ;;
        *)
            log_error "Invalid service action: $action"
            return 1
            ;;
    esac
}

# Validation functions
validate_input() {
    local input="$1"
    local pattern="$2"
    local description="$3"
    
    if [[ "$input" =~ $pattern ]]; then
        return 0
    else
        log_error "Invalid $description: $input"
        return 1
    fi
}

validate_url() {
    local url="$1"
    if curl -fsSL --head "$url" &> /dev/null; then
        return 0
    else
        log_error "Invalid or unreachable URL: $url"
        return 1
    fi
}

# Cleanup functions
cleanup_temp_files() {
    local temp_files=("$@")
    
    log_info "Cleaning up temporary files..."
    for file in "${temp_files[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_info "Removed: $file"
        fi
    done
}

# System information
get_system_info() {
    log_info "System Information:"
    log_info "  OS: $(lsb_release -d | cut -f2)"
    log_info "  Kernel: $(uname -r)"
    log_info "  Architecture: $(uname -m)"
    log_info "  Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    log_info "  Disk Space: $(df -h / | awk 'NR==2 {print $4}') available"
}

# Export all functions for use in other scripts
export -f log_info log_warn log_error log_step log_success show_progress
export -f setup_error_handling handle_error cleanup_on_error
export -f check_root_privileges check_sudo_privileges check_internet_connectivity check_disk_space
export -f check_command install_package install_packages install_docker
export -f setup_python_environment create_directory_structure download_file clone_repository
export -f manage_service validate_input validate_url cleanup_temp_files get_system_info

log_info "Shared installation functions library loaded successfully"
