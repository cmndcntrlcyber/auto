#!/bin/bash

# Replace 'your_domain_name' with your actual domain name and provide admin credentials

USER='your-username'
PASSWORD='your-password'
DOMAIN_NAME='your_domain_name.com'
SERVER='windows_AD_server_IP_address' # The IP address of the AD server

# Ensure Samba is installed (use apt-get install samba if it's not already)
apt-get install -y samba

# Add your Ubuntu host to Active Directory using dsconfig
dsadd user "YourUsername" -S "$USER:$PASSWORD" -D $SERVER/$DOMAIN_NAME 2>/dev/null

echo "Host $USER has been added to the domain $DOMAIN_NAME."