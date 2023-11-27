#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error occurred at line $1 with exit code $2"
    exit $2
}

# Trap errors and call the handle_error function
trap 'handle_error $LINENO $?' ERR

echo "What is the name of your app?"
read name

# Check if 'curl' is installed
if ! command -v curl &> /dev/null; then
    echo "curl could not be found, please install it."
    exit 1
fi

# Execute curl with error checking
curl -fSL "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/start-apache2.sh" | bash

# Navigate and create directories with error checking
cd /var/www/ || handle_error $LINENO $?
mkdir -p apps
cd apps || handle_error $LINENO $?

# Clone the git repository with error checking
if ! git clone "https://github.com/cmndcntrlcyber/Landing2.git"; then
    echo "Failed to clone the repository."
    exit 1
fi

mv Landing2 "$name" || handle_error $LINENO $?
cd "$name" || handle_error $LINENO $?

# Replace text in file with error checking
if ! sed -i "s/\$old_name/$name/g" 000-default.conf; then
    echo "Failed to substitute name in configuration file."
    exit 1
fi

# Enable site with error checking
if ! sudo a2ensite 000-default.conf; then
    echo "Failed to enable site."
    exit 1
fi

# Setting up Python virtual environment with error checking
if ! python -m venv "$name"; then
    echo "Failed to create Python virtual environment."
    exit 1
fi

source "$name/bin/activate" || handle_error $LINENO $?

# Download and execute Python script with error checking
if ! curl -fSL "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/prep-flask-web.py" | python3; then
    echo "Failed to execute Python setup script."
    exit 1
fi

source venv/bin/activate || handle_error $LINENO $?
export FLASK_APP="$name.py"
