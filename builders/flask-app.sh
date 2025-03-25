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
        return 1
    fi
    return 0
}

# Function to check and install dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    # List of required commands
    local dependencies=("wget" "git" "python3" "curl" "apache2")
    
    for cmd in "${dependencies[@]}"; do
        if ! check_command "$cmd"; then
            warning "$cmd is not installed. Attempting to install..."
            if ! apt-get update && apt-get install -y "$cmd"; then
                error "Failed to install $cmd. Please install it manually."
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
    rm -f start-apache2.sh
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

# Download and run start-apache2.sh
log "Setting up Apache2..."
download_file "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/start-apache2.sh" "start-apache2.sh"
if ! bash start-apache2.sh; then
    warning "Failed to run start-apache2.sh, but continuing with setup..."
fi

# Create app directories
log "Creating application directories..."
mkdir -p /var/www/apps || error "Failed to create /var/www/apps directory"
cd /var/www/apps || error "Failed to change to /var/www/apps directory"

# Clone repository
log "Cloning application template..."
if ! git clone "https://github.com/cmndcntrlcyber/Landing2.git"; then
    error "Failed to clone the repository"
fi

# Rename directory
log "Setting up application '$app_name'..."
mv Landing2 "$app_name" || error "Failed to rename directory"
cd "$app_name" || error "Failed to change to application directory"

# Update configuration
log "Configuring Apache2..."
if [ -f "000-default.conf" ]; then
    # Replace the template name with the app name
    if ! sed -i "s/Landing2/$app_name/g" 000-default.conf; then
        error "Failed to update Apache configuration"
    fi
else
    warning "Apache configuration file 000-default.conf not found. Skipping configuration."
fi

# Enable site
log "Enabling site in Apache2..."
if ! sudo a2ensite 000-default.conf; then
    warning "Failed to enable site in Apache2, but continuing with setup..."
fi

# Create and activate virtual environment
log "Setting up Python virtual environment..."
if ! python3 -m venv "$app_name"; then
    # Try with python command if python3 fails
    if ! python -m venv "$app_name"; then
        error "Failed to create virtual environment"
    fi
fi

# Source virtual environment
log "Activating virtual environment..."
source "$app_name/bin/activate" || error "Failed to activate virtual environment"

# Run prep script
log "Preparing Flask web application..."
if ! curl -fsSL "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/prep-flask-web.py" | python3; then
    warning "Failed to run preparation script, but continuing with setup..."
fi

# Set Flask app
export FLASK_APP="$app_name.py"

# Install Flask and other dependencies
log "Installing Flask and dependencies..."
pip install flask gunicorn || warning "Failed to install some dependencies"

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
