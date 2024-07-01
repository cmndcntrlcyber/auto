#!/bin/bash

# Function to create a user and setup RDP
create_user() {
    local username=$1
    sudo adduser --gecos "" --disabled-password $username
    sudo adduser $username xrdp
    echo "startxfce4" > /home/$username/.xsession
    sudo chown $username:$username /home/$username/.xsession
}

# Check arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 [-userlist filename] [-web-list url] username1 [username2 ...]"
    exit 1
fi

# Update system packages and install xrdp
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install xrdp -y
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Process arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -userlist)
            FILENAME="$2"
            shift # past argument
            shift # past value
            ;;
        -web-list)
            URL="$2"
            shift # past argument
            shift # past value
            ;;
        *)
            create_user $key
            shift # past argument
            ;;
    esac
done

# Process userlist file if provided
if [[ ! -z $FILENAME ]]; then
    if [[ $FILENAME == *.txt || $FILENAME == *.csv ]]; then
        while IFS= read -r line; do
            create_user $line
        done < $FILENAME
    else
        echo "Unsupported file type. Please use .txt or .csv."
    fi
fi

# Process web-list if provided
if [[ ! -z $URL ]]; then
    curl -s $URL | while IFS= read -r line; do
        create_user $line
    done
fi

sudo systemctl restart xrdp
echo "User creation and RDP setup complete."