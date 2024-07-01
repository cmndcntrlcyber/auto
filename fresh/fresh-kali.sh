#!/bin/bash

# Create directories using a loop
directories=(
    vpns files /github /recon /recon/wordlists /targets /targets/htb
    /targets/thm /targets/bounty /targets/bounty/h1 /targets/bounty/bugcrowd
    /payloads /post /engaged /engaged/admin /engaged/osint /engaged/recon
    /engaged/targets /engaged/targets/domain /engaged/targets/domain/hostname
    /engaged/targets/domain/exfil /engaged/targets/domain/hostname/exfil
    /engaged/screenshots /engaged/payloads /engaged/payloads/entry
    /engaged/payloads/privesc /engaged/payloads/persistence /engaged/logs
    /engaged/Readme.md /var/log/session
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
done

# Cloning Git repositories
cd /github

repos=(
    https://github.com/swisskyrepo/PayloadsAllTheThings.git
    https://github.com/1N3/IntruderPayloads.git
    https://github.com/fuzzdb-project/fuzzdb.git
    https://github.com/The-Art-of-Hacking/h4cker.git
    https://github.com/OlivierLaflamme/Cheatsheet-God.git
    https://github.com/almandin/fuxploider.git
    https://github.com/EmpireProject/Empire.git
    https://github.com/BloodHoundAD/BloodHound.git
    https://github.com/samratashok/nishang.git
    https://github.com/Tib3rius/AutoRecon.git
    https://github.com/fin3ss3g0d/evilgophish.git
    https://github.com/mttaggart/rustyneedle.git
)

for repo in "${repos[@]}"; do
    git clone "$repo"
done

mv IntruderPayloads intrude
mv PayloadsAllTheThings patt
mv SecLists seclists
mv fuzzdb /recon/wordlists
mv intrude /recon/wordlists
mv patt /recon/wordlists
mv seclists /recon/wordlists
mv fuxploider /recon
mv impacket /recon/impacket
mv nishang /post/win/nishang
mv AutoRecon /recon/AutoRecon
mv rustyneedle /payloads/rustyneedle

pip3 install -r /github/impacket/requirements.txt
cd /recon/impacket && python3 ./setup.py install


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
    apt-get install -y gccgo-go
    apt-get install -y golang-go

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
    wget wget https://golang.org/dl/go1.21.linux-amd64.tar.gz
    sudo tar -C /usr/local -xvf go1.21.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
fi
