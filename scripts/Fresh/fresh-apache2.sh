sudo apt update
sudo apt install apache2

sudo apt install certbot python3-certbot-apache libapache2-mod-wsgi-py3 # Should be handled during install script.

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
sudo a2enmod ssl
sudo a2ensite 000-default.conf
sudo systemctl restart apache2