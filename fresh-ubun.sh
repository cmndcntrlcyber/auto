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
    apt-get install spice-vdagent -y
    apt-get install -y git 
    apt-get install -y containerd
    apt-get install -y docker.io 
    apt-get install -y docker-compose 
    apt-get install -y ca-certificates 
    apt-get install -y certbot 
    apt-get install -y curl 
    apt-get install -y gnupg 
    apt-get install -y lsb-release 
    apt-get install -y snapd 
    apt-get install -y npm 
    apt-get install -y default-jdk
fi

# Rust installation
if ask_to_install "Rust"; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source "$HOME/.cargo/env"
    rustup target add x86_64-pc-windows-gnu
    sudo apt-get install -y gcc-mingw-w64-x86-64
fi

# Go installation
if ask_to_install "Go"; then
    wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz
    sudo tar -C /usr/local -xvf go1.20.4.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
fi