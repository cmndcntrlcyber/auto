import subprocess
import sys

def install_pip(package):
    subprocess.check_call([sys.executable, "-m", "pip", "install", package])

def install_apt(package):
    subprocess.check_call(["sudo", "apt-get", "install", "-y", package])

pip_packages = [
    "Flask",
    "Flask-SQLAlchemy",
    "psycopg2-binary",
    "Werkzeug",
    "Flask-WTF",     # Added Flask-WTF
    "WTForms"        # Added WTForms
]

apt_packages = [
    "postgresql",
    "apache2",
    "libapache2-mod-wsgi-py3",
    "python3",
    "python3-pip"
]

print("Installing pip packages...")
for package in pip_packages:
    install_pip(package)

print("Installing apt packages...")
for package in apt_packages:
    install_apt(package)

print("All packages installed successfully.")
