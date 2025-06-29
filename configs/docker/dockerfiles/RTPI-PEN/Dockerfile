FROM kasmweb/kali-rolling-desktop:1.16.1
USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

######### Customize Container Here ###########

# Update system and install essential packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    jython \
    python3-pip \
    python-is-python3 \
    python3-virtualenv \
    git \
    containerd \
    ca-certificates \
    certbot \
    curl \
    gnupg \
    lsb-release \
    snapd \
    npm \
    default-jdk \
    gccgo-go \
    golang-go \
    build-essential

# Install Red Team specific packages
RUN apt-get install -y \
    nmap \
    metasploit-framework \
    hashcat \
    hydra \
    proxychains4 \
    powershell \
    mingw-w64 \
    wine \
    wireshark \
    python3-impacket \
    bloodhound \
    crackmapexec \
    exploitdb \
    nbtscan \
    smbclient \
    net-tools

# Install Python packages for C2 development and operation
RUN pip3 install \
    pwntools \
    pycrypto \
    cryptography \
    requests \
    pyOpenSSL

# Set up RTPI environment
RUN mkdir -p /opt/rtpi && \
    cd /opt/rtpi && \
    git clone https://github.com/BC-SECURITY/Empire.git

# Create desktop shortcuts for common tools
RUN mkdir -p $HOME/Desktop && \
    echo "[Desktop Entry]" > $HOME/Desktop/Metasploit.desktop && \
    echo "Version=1.0" >> $HOME/Desktop/Metasploit.desktop && \
    echo "Type=Application" >> $HOME/Desktop/Metasploit.desktop && \
    echo "Name=Metasploit Framework" >> $HOME/Desktop/Metasploit.desktop && \
    echo "Comment=Penetration Testing Framework" >> $HOME/Desktop/Metasploit.desktop && \
    echo "Exec=gnome-terminal -- msfconsole" >> $HOME/Desktop/Metasploit.desktop && \
    echo "Icon=applications-internet" >> $HOME/Desktop/Metasploit.desktop && \
    echo "Terminal=false" >> $HOME/Desktop/Metasploit.desktop && \
    chmod +x $HOME/Desktop/Metasploit.desktop

RUN echo "[Desktop Entry]" > $HOME/Desktop/Empire.desktop && \
    echo "Version=1.0" >> $HOME/Desktop/Empire.desktop && \
    echo "Type=Application" >> $HOME/Desktop/Empire.desktop && \
    echo "Name=PowerShell Empire" >> $HOME/Desktop/Empire.desktop && \
    echo "Comment=PowerShell C2 Framework" >> $HOME/Desktop/Empire.desktop && \
    echo "Exec=gnome-terminal --working-directory=/opt/rtpi/Empire -- ./ps-empire" >> $HOME/Desktop/Empire.desktop && \
    echo "Icon=applications-system" >> $HOME/Desktop/Empire.desktop && \
    echo "Terminal=false" >> $HOME/Desktop/Empire.desktop && \
    chmod +x $HOME/Desktop/Empire.desktop

RUN echo "[Desktop Entry]" > $HOME/Desktop/Nmap.desktop && \
    echo "Version=1.0" >> $HOME/Desktop/Nmap.desktop && \
    echo "Type=Application" >> $HOME/Desktop/Nmap.desktop && \
    echo "Name=Nmap Network Scanner" >> $HOME/Desktop/Nmap.desktop && \
    echo "Comment=Network Discovery and Security Auditing" >> $HOME/Desktop/Nmap.desktop && \
    echo "Exec=gnome-terminal -- nmap" >> $HOME/Desktop/Nmap.desktop && \
    echo "Icon=applications-internet" >> $HOME/Desktop/Nmap.desktop && \
    echo "Terminal=false" >> $HOME/Desktop/Nmap.desktop && \
    chmod +x $HOME/Desktop/Nmap.desktop

# Create a welcome script
RUN echo '#!/bin/bash' > $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "Welcome to RTPI - Red Team Penetration Testing Infrastructure"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "Available Tools:"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "- Metasploit Framework"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "- PowerShell Empire (C2)"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "- Nmap Network Scanner"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "- Hashcat Password Cracker"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "- Hydra Brute Force Tool"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "- BloodHound AD Analysis"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "- CrackMapExec"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "- Wireshark Network Analyzer"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo ""' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "Access SysReptor reporting at: http://localhost:9000"' >> $HOME/Desktop/rtpi-welcome.sh && \
    echo 'echo "Access Portainer management at: https://localhost:9443"' >> $HOME/Desktop/rtpi-welcome.sh && \
    chmod +x $HOME/Desktop/rtpi-welcome.sh

######### End Customizations ###########

RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME

ENV HOME /home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000
