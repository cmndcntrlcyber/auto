#!/bin/bash/

sudo cp -r /opt/login/ /var/www/apps/login
sudo cp -r /opt/register/ /var/www/apps/register

export FLASK_APP=/var/www/apps/login.py
export FLASK_APP=/var/www/apps/register.py

sudo systemctl reload apache2
sudo systemctl restart apache2
