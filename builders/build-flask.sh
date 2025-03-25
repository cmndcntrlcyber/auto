#!/bin/bash

# Flask Application Builder Script
# This script sets up a Flask application with Apache2

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
        error "$1 is not installed. Please install it and try again."
    fi
}

# Function to check and install dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    # List of required commands
    local dependencies=("wget" "git" "python3" "virtualenv" "curl" "apache2")
    
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            warning "$cmd is not installed. Attempting to install..."
            if [ "$cmd" = "virtualenv" ]; then
                if ! pip3 install virtualenv; then
                    error "Failed to install virtualenv. Please install it manually."
                fi
            else
                if ! apt-get update && apt-get install -y "$cmd"; then
                    error "Failed to install $cmd. Please install it manually."
                fi
            fi
        fi
    done
    
    log "All dependencies are installed."
}

# Function to download a file with verification
download_file() {
    local url="$1"
    local output_file="$2"
    
    log "Downloading $output_file..."
    if ! wget -q "$url" -O "$output_file"; then
        error "Failed to download $url"
    fi
    
    if [ ! -f "$output_file" ]; then
        error "Download failed: $output_file not found"
    fi
    
    log "Successfully downloaded $output_file"
}

# Function to clean up temporary files
cleanup() {
    log "Cleaning up temporary files..."
    rm -f fresh-ubun.sh start-apache2.sh
    log "Cleanup complete."
}

# Main script execution starts here
log "Starting Flask application setup..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
fi

# Check dependencies
check_dependencies

# Prompt for app name
echo "What is the name of your app? (alphanumeric characters only)"
read -r app_name

# Validate app name
if [[ ! "$app_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "Invalid app name. Please use only alphanumeric characters, hyphens, and underscores."
fi

# Check if app directory already exists
if [ -d "/var/www/apps/$app_name" ]; then
    error "An application with the name '$app_name' already exists in /var/www/apps/. Please choose a different name."
fi

# Download and run fresh-ubun.sh
log "Setting up the environment..."
download_file "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/fresh-ubun.sh" "fresh-ubun.sh"
if ! bash fresh-ubun.sh; then
    error "Failed to run fresh-ubun.sh"
fi

# Download and run start-apache2.sh
log "Setting up Apache2..."
download_file "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/start-apache2.sh" "start-apache2.sh"
if ! bash start-apache2.sh; then
    error "Failed to run start-apache2.sh"
fi

# Create app directories
log "Creating application directories..."
mkdir -p /var/www/apps || error "Failed to create /var/www/apps directory"
cd /var/www/apps || error "Failed to change to /var/www/apps directory"

# Clone repository
log "Cloning application template..."
if ! git clone "https://github.com/cmndcntrl/ztsc.git"; then
    error "Failed to clone the repository"
fi

# Rename directory
log "Setting up application '$app_name'..."
mv ztsc "$app_name" || error "Failed to rename directory"
cd "$app_name" || error "Failed to change to application directory"

# Update configuration
log "Configuring Apache2..."
if ! sed -i "s/ztsc/$app_name/g" 000-default.conf; then
    error "Failed to update Apache configuration"
fi

# Enable site
log "Enabling site in Apache2..."
if ! sudo a2ensite 000-default.conf; then
    error "Failed to enable site in Apache2"
fi

# Run prep script
log "Preparing Flask web application..."
if ! curl -s "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/prep-flask-web.py" | python3; then
    error "Failed to run preparation script"
fi

# Create and activate virtual environment
log "Setting up Python virtual environment..."
if ! virtualenv -p python3 "$app_name"; then
    error "Failed to create virtual environment"
fi

# Source virtual environment
log "Activating virtual environment..."
source "$app_name/bin/activate" || error "Failed to activate virtual environment"

# Set Flask app
export FLASK_APP="$app_name.py"

# Clean up
cleanup

log "======================================================================"
log "Flask application '$app_name' has been successfully set up!"
log ""
log "Application directory: /var/www/apps/$app_name"
log "Virtual environment: /var/www/apps/$app_name/$app_name"
log ""
log "To start the application:"
log "  1. cd /var/www/apps/$app_name"
log "  2. source $app_name/bin/activate"
log "  3. flask run --host=0.0.0.0"
log ""
log "Your application will be available at: http://your-server-ip:5000"
log "======================================================================"
