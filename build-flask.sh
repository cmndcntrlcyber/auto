#!/bin/bash

echo "What is the name of your app?"
read name

curl "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/start-apache2.sh" | bash

cd /var/www/; mkdir apps; cd apps
git clone "https://github.com/cmndcntrl/ztsc.git"
mv ztsc $name
cd $name;

sed -i 's/ztsc/$name/g' 000-default.conf
sudo a2ensite 000-default.conf
python -m venv $name;  source $name/bin/activate # $name here begins representing the virutal environment
curl "https://raw.githubusercontent.com/cmndcntrlcyber/auto/main/prep-flask-web.py" | python3
source $name/bin/activate
export FLASK_APP=$name.py