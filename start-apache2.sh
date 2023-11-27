#!/bin/bash

# Update package lists
sudo apt update

# Install Apache2 if not installed
if ! command -v apache2 > /dev/null; then
    echo "Installing Apache2..."
    sudo apt install apache2 -y
fi

# Function to install Let's Encrypt and obtain a certificate
setup_lets_encrypt() {
    echo "Installing Certbot and dependencies for Let's Encrypt..."
    sudo apt install certbot python3-certbot-apache libapache2-mod-wsgi-py3 -y
    echo "Obtaining an SSL Certificate from Let's Encrypt..."
    sudo certbot --apache
}

# Function to create a self-signed certificate
create_self_signed_cert() {
    echo "Creating a self-signed SSL certificate..."
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
    echo "Manually configure Apache2 to use the self-signed certificate..."
    echo "Edit the Apache configuration file, then enable the SSL module and site configuration."
}

echo "Choose SSL setup method:"
echo "1. Let's Encrypt (recommended for production)"
echo "2. Self-signed certificate (for testing)"
read -p "Enter your choice (1 or 2): " 2

case $ssl_choice in
    1)
        setup_lets_encrypt
        ;;
    2)
        create_self_signed_cert
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Enable SSL module and restart Apache
sudo a2enmod ssl
sudo systemctl restart apache2

echo "Apache2 setup complete."
