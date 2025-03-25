#!/bin/bash

# Supabase Setup Script
# This script sets up Supabase CLI and initializes a new project

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
    rm -f fresh-ubun.sh supabase_*.deb
    log "Cleanup complete."
}

# Function to get the latest Supabase CLI version
get_latest_supabase_version() {
    log "Checking for the latest Supabase CLI version..."
    
    if ! check_command "curl"; then
        warning "curl is not installed. Using default version."
        echo "v1.133.3"
        return
    fi
    
    local latest_version
    latest_version=$(curl -s "https://api.github.com/repos/supabase/cli/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    
    if [ -z "$latest_version" ]; then
        warning "Failed to get latest version. Using default version."
        echo "v1.133.3"
    else
        log "Latest version is $latest_version"
        echo "$latest_version"
    fi
}

# Main script execution starts here
log "Starting Supabase setup..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
fi

# Check if Supabase is already installed
if check_command "supabase"; then
    log "Supabase CLI is already installed."
    supabase_version=$(supabase --version 2>&1 | head -n 1)
    log "Current version: $supabase_version"
    
    read -p "Do you want to reinstall/upgrade Supabase CLI? (y/n): " -r reinstall
    if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
        log "Skipping Supabase CLI installation."
    else
        log "Proceeding with reinstallation..."
    fi
else
    reinstall="y"
fi

# Download and run fresh-ubun.sh
log "Setting up the environment..."
if ! wget -q "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/scripts/fresh-ubun.sh" -O "fresh-ubun.sh"; then
    # Try alternative path if the first one fails
    if ! wget -q "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/fresh-ubun.sh" -O "fresh-ubun.sh"; then
        error "Failed to download fresh-ubun.sh"
    fi
fi

if [ ! -f "fresh-ubun.sh" ]; then
    error "Download failed: fresh-ubun.sh not found"
fi

log "Running environment setup script..."
if ! bash fresh-ubun.sh; then
    error "Failed to run fresh-ubun.sh"
fi

# Install Supabase CLI if needed
if [[ "$reinstall" =~ ^[Yy]$ ]]; then
    # Get the latest version
    version=$(get_latest_supabase_version)
    version_num=${version#v}  # Remove 'v' prefix
    
    log "Installing Supabase CLI version $version_num..."
    
    # Download Supabase CLI
    deb_file="supabase_${version_num}_linux_amd64.deb"
    download_url="https://github.com/supabase/cli/releases/download/${version}/${deb_file}"
    
    log "Downloading Supabase CLI from $download_url..."
    if ! wget -q "$download_url" -O "$deb_file"; then
        error "Failed to download Supabase CLI"
    fi
    
    if [ ! -f "$deb_file" ]; then
        error "Download failed: $deb_file not found"
    fi
    
    # Install Supabase CLI
    log "Installing Supabase CLI..."
    if ! dpkg -i "$deb_file"; then
        error "Failed to install Supabase CLI"
    fi
    
    log "Supabase CLI installed successfully."
fi

# Install VSCode if not already installed
if ! check_command "code"; then
    log "Installing Visual Studio Code..."
    
    # Install snapd if not already installed
    if ! check_command "snap"; then
        log "Installing snapd..."
        if ! apt-get update && apt-get install -y snapd; then
            error "Failed to install snapd"
        fi
    fi
    
    # Install VSCode
    log "Installing Visual Studio Code via snap..."
    if ! snap install code --classic; then
        error "Failed to install Visual Studio Code"
    fi
    
    log "Visual Studio Code installed successfully."
else
    log "Visual Studio Code is already installed."
fi

# Initialize Supabase project
log "Initializing Supabase project..."

# Ask for project directory
read -p "Enter the directory name for your Supabase project (default: my-supabase-project): " project_dir
project_dir=${project_dir:-my-supabase-project}

# Create project directory if it doesn't exist
if [ ! -d "$project_dir" ]; then
    log "Creating project directory: $project_dir"
    mkdir -p "$project_dir"
fi

# Change to project directory
cd "$project_dir" || error "Failed to change to project directory"

# Initialize Supabase project
log "Running supabase init..."
if ! supabase init; then
    error "Failed to initialize Supabase project"
fi

# Start Supabase
log "Starting Supabase..."
if ! supabase start; then
    error "Failed to start Supabase"
fi

# Clean up
cleanup

log "======================================================================"
log "Supabase has been successfully set up!"
log ""
log "Project directory: $(pwd)"
log ""
log "Supabase Studio is available at: http://localhost:54323"
log "API URL: http://localhost:54321"
log ""
log "To stop Supabase: cd $(pwd) && supabase stop"
log "To start Supabase again: cd $(pwd) && supabase start"
log ""
log "For more information, visit: https://supabase.com/docs"
log "======================================================================"
