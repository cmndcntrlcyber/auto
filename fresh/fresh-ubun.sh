#!/bin/bash

# Function to ask for user confirmation
ask_to_install() {
    while true; do
        read -p "Do you want to install $1? (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Google Chrome installation
if ask_to_install "Google Chrome"; then
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    apt install ./google-chrome-stable_current_amd64.deb
fi

# General apt packages installation
if ask_to_install "General apt packages"; then
    apt-get install -y jython
    apt-get install -y python3-pip
    apt-get install -y python-is-python3
    apt-get install -y python3-virtualenv
    apt-get install -y tldr
    apt-get install -y spice-vdagent 
    apt-get install -y git 
    apt-get install -y containerd
    apt-get install -y ca-certificates 
    apt-get install -y certbot 
    apt-get install -y curl 
    apt-get install -y gnupg 
    apt-get install -y lsb-release 
    apt-get install -y snapd 
    apt-get install -y npm 
    apt-get install -y default-jdk
    apt-get install -y gccgo-go
    apt-get install -y golang-go
    apt-get install -y virt-manager
    apt-get install -y tilix

fi

# VS-Code Apt Installation
## Install Signing Key
sudo apt-get install wget gpg &&
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg &&
sudo install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg &&
rm -f microsoft.gpg

## Create Sources
sudo touch /etc/apt/sources.list.d/vscode.sources
sudo echo "Types: deb" > /etc/apt/sources.list.d/vscode.sources
sudo echo "URIs: https://packages.microsoft.com/repos/code" >> /etc/apt/sources.list.d/vscode.sources
sudo echo "Suites: stable" >> /etc/apt/sources.list.d/vscode.sources
sudo echo "Components: main" >> /etc/apt/sources.list.d/vscode.sources
sudo echo "Architectures: amd64,arm64,armhf" >> /etc/apt/sources.list.d/vscode.sources
sudo echo "Signed-By: /usr/share/keyrings/microsoft.gpg" >> /etc/apt/sources.list.d/vscode.sources

# Update cache and install
sudo apt install apt-transport-https &&
sudo apt update &&
sudo apt install code # or code-insiders


#Docker Installation
if ask_to_install "Docker"; then
    echo "Remove Conflicting Packages:"
    echo "-------------------------------------"
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done


    echo "Add Docker's official GPG key:"
    echo "-------------------------------------"

    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "Adding the repository to Apt sources:"
    echo "-------------------------------------"
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    echo "Installing the Latest Version"
    echo "-------------------------------------"

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# Rust installation
if ask_to_install "Rust"; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source "$HOME/.cargo/env"
    rustup target add x86_64-pc-windows-gnu
    sudo apt-get install -y gcc-mingw-w64-x86-64
fi
