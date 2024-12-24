#!/bin/bash

apt-get update -y
apt-get install -y jython
apt-get install -y python3-pip
apt-get install -y python-is-python3
apt-get install -y python3-virtualenv
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

echo "Removing Conflicting Packages:"
echo "-------------------------------------"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done

echo "Adding Docker's official GPG key:"
echo "-------------------------------------"
sudo apt-get update -y
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
sudo apt-get update -y

echo "Installing the Latest Version"
echo "-------------------------------------"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

