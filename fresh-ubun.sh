wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install ./google-chrome-stable_current_amd64.deb

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

#Install Rust and include crates for Windows Binaries
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustup target add x86_64-pc-windows-gnu
sudo apt-get install -y gcc-mingw-w64-x86-64

wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go1.20.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin