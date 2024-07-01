sudo apt install network-manager-openconnect network-manager-openconnect-gnome
sudo systemctl restart network-manager.service

# wget http://ftp.us.debian.org/debian/pool/main/n/network-manager-openconnect/network-manager-openconnect_1.2.10-1_amd64.deb 
# dpkg -i network-manager-openconnect_1.2.10-1_amd64.deb 

# wget http://ftp.us.debian.org/debian/pool/main/n/network-manager-openconnect/network-manager-openconnect-gnome_1.2.10-1_amd64.deb 
# dpkg -i network-manager-openconnect-gnome_1.2.10-1_amd64.deb

wget http://ftp.us.debian.org/debian/pool/main/n/network-manager-openconnect/network-manager-openconnect-gnome_1.2.10-3+b1_amd64.deb
dpkg -i network-manager-openconnect-gnome_1.2.10-3+b1_amd64.deb

wget http://ftp.us.debian.org/debian/pool/main/n/network-manager-openconnect/network-manager-openconnect_1.2.10-3+b1_amd64.deb
dpkg -i network-manager-openconnect_1.2.10-3+b1_amd64.deb

