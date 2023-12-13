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
    https://github.com/danielmiessler/SecLists.git
    https://github.com/almandin/fuxploider.git
    https://github.com/EmpireProject/Empire.git
    https://github.com/BloodHoundAD/BloodHound.git
    https://github.com/SecureAuthCorp/impacket.git
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

echo 'alias vuln-init="sudo bash /recon/scanners/vuln.sh"' >> ~/.bashrc
echo 'alias vuln-init="sudo bash /recon/scanners/vuln.sh"' >> ~/.zshrc

echo 'alias recon ="cd /recon/"' >> ~/.bashrc
echo 'alias recon="cd /recon/"' >> ~/.zshrc

echo 'alias scanners="cd /recon/scanners"' >> ~/.bashrc
echo 'alias scanners="cd /recon/scanners"' >> ~/.zshrc

echo 'alias payloads="cd /payloads"' >> ~/.bashrc
echo 'alias payloads="cd /payloads"' >> ~/.zshrc

echo 'alias bounty="cd /targets/bounty"' >> ~/.bashrc
echo 'alias bounty="cd /targets/bounty"' >> ~/.zshrc

echo 'alias targets="cd /targets"' >> ~/.bashrc
echo 'alias targets="cd /targets"' >> ~/.zshrc

echo 'alias files="cd /"' >> ~/.bashrc
echo 'alias files="cd /"' >> ~/.zshrc

echo 'alias "$user-vpn"="openvpn /vpns/$user.ovpn"' >> ~/.bashrc
echo 'alias "$user-vpn"="openvpn /vpns/$user.ovpn"' >> ~/.zshrc

echo 'alias "htb-lab-vpn"="openvpn /vpns/lab_cmndcntrl.ovpn"' >> ~/.bashrc
echo 'alias "htb-lab-vpn"="openvpn /vpns/lab_cmndcntrl.ovpn"' >> ~/.zshrc

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install ./google-chrome-stable_current_amd64.deb

sudo apt install -y certbot python3-certbot-apache default-jdk jython tldr spice-vdagent git containerd docker.io docker-compose ca-certificates certbot curl gnupg lsb-release snapd npm 

sudo apt install -y certbot python3-certbot-apache default-jdk

#Install Rust and include crates for Windows Binaries
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustup target add x86_64-pc-windows-gnu
sudo apt-get install -y gcc-mingw-w64-x86-64

wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go1.20.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin