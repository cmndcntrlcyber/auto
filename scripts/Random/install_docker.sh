#!/usr/bin/bash

if [ "$(id --user)" -ne "0" ];then
    printf "This script requires root priviledges\n"
    exit 1
fi

OS_NAME=$(source /etc/os-release && echo "$ID_LIKE")
if [ -z "$OS_NAME" ]; then
    OS_NAME=$(source /etc/os-release && echo "$ID")
    OS_CODENAME=$(source /etc/os-release && echo "$VERSION_CODENAME")
else
    if [ "$OS_NAME" == "debian" ];then
        OS_CODENAME='bookworm'
    else
        OS_CODENAME='mantic'
    fi
fi
OS_ARCH=$(dpkg --print-architecture)

apt-get install -y curl gnupg
curl -fsSL "https://download.docker.com/linux/${OS_NAME}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

(cat > "/etc/apt/sources.list.d/docker.sources") <<EOF
Architectures: ${OS_ARCH}
Enabled: yes
X-Repolib-Name: docker
Signed-By: /etc/apt/keyrings/docker.gpg
Suites: ${OS_CODENAME}
Components: stable
Trusted: yes
Types: deb
URIs: https://download.docker.com/linux/${OS_NAME}
EOF

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

exit 0
