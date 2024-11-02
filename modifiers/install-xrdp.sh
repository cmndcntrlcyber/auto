wget https://gitlab.com/kalilinux/recipes/kali-scripts/-/raw/main/xfce4.sh
chmod +x xfce4.sh
sudo ./xfce4.sh

sudo apt install -y xrdp
sudo systemctl status xrdp
sudo systemctl enable xrdp --now
sudo adduser rdp-cmndcntrl
sudo adduser rdp-cmndcntrl ssl-cert
sudo systemctl restart xrdp
