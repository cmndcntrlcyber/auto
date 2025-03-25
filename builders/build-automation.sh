#!/bin/bash

# Gitea and Drone CI Installation Script with Cloudflare Certificate Setup
# Configuration is handled via a .env file
# Domains: gitea.c3s.nexus & drone.c3s.nexus

set -e

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function for logging
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
fi

# Determine installation directory
DEFAULT_DATA_DIR="/opt/gitea-drone"
DATA_DIR=${DATA_DIR:-$DEFAULT_DATA_DIR}

# Create .env file path
ENV_FILE="${DATA_DIR}/.env"

# Create .env file if it doesn't exist
create_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        log "Creating .env file..."
        mkdir -p $(dirname "$ENV_FILE")
        cat > "$ENV_FILE" << EOF
# Cloudflare API Key - Used for DNS challenge when generating SSL certificates
# Replace with your actual API key
CLOUDFLARE_API_KEY=your-cloudflare-api-key

# Domain Configuration
GITEA_DOMAIN=gitea.c3s.nexus
DRONE_DOMAIN=drone.c3s.nexus

# Version Information
GITEA_VERSION=1.21.3
DOCKER_COMPOSE_VERSION=2.24.5

# Directory Configuration
DATA_DIR=${DATA_DIR}

# Auto-generated Secrets - DO NOT CHANGE AFTER INITIAL SETUP
DB_PASSWORD=$(openssl rand -hex 16)
GITEA_SECRET=$(openssl rand -hex 16)
DRONE_RPC_SECRET=$(openssl rand -hex 32)

# Admin Credentials - Change after setup
GITEA_ADMIN_USER=gitea-admin
GITEA_ADMIN_PASSWORD=gitea-admin-password
GITEA_ADMIN_EMAIL=your-admin-email
EOF
        chmod 600 "$ENV_FILE"
        log "Created .env file at $ENV_FILE"
    else
        log ".env file already exists at $ENV_FILE. Using existing configuration."
    fi
}

# Create directory structure and .env file
mkdir -p ${DATA_DIR}
create_env_file

# Load environment variables from .env file
log "Loading configuration from .env file..."
source "$ENV_FILE"

# Create necessary directories
log "Creating directories..."
mkdir -p ${DATA_DIR}/{gitea,drone,postgres,certs}
chmod -R 750 ${DATA_DIR}

# Install dependencies
log "Installing dependencies..."
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    openssl \
    certbot \
    python3-certbot-dns-cloudflare \
    jq

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    log "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Setup Cloudflare credentials for certificate generation
log "Setting up Cloudflare credentials for certificate generation..."
mkdir -p /root/.secrets/certbot
cat > /root/.secrets/certbot/cloudflare.ini << EOF
dns_cloudflare_api_key = ${CLOUDFLARE_API_KEY}
EOF
chmod 600 /root/.secrets/certbot/cloudflare.ini

# Generate certificates using Certbot with Cloudflare DNS challenge
log "Generating SSL certificates using Certbot and Cloudflare..."
certbot certonly --dns-cloudflare \
    --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini \
    --agree-tos --no-eff-email \
    -m ${GITEA_ADMIN_EMAIL} \
    -d ${GITEA_DOMAIN} \
    --cert-name ${GITEA_DOMAIN}

certbot certonly --dns-cloudflare \
    --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini \
    --agree-tos --no-eff-email \
    -m ${GITEA_ADMIN_EMAIL} \
    -d ${DRONE_DOMAIN} \
    --cert-name ${DRONE_DOMAIN}

# Copy certificates to our working directory
log "Copying certificates to working directory..."
cp /etc/letsencrypt/live/${GITEA_DOMAIN}/fullchain.pem ${DATA_DIR}/certs/gitea-cert.pem
cp /etc/letsencrypt/live/${GITEA_DOMAIN}/privkey.pem ${DATA_DIR}/certs/gitea-key.pem
cp /etc/letsencrypt/live/${DRONE_DOMAIN}/fullchain.pem ${DATA_DIR}/certs/drone-cert.pem
cp /etc/letsencrypt/live/${DRONE_DOMAIN}/privkey.pem ${DATA_DIR}/certs/drone-key.pem

# Create .env file for docker-compose
log "Creating docker-compose .env file..."
cat > ${DATA_DIR}/docker-compose.env << EOF
# Database Configuration
POSTGRES_USER=gitea
POSTGRES_PASSWORD=${DB_PASSWORD}
POSTGRES_DB=gitea

# Gitea Configuration
GITEA_VERSION=${GITEA_VERSION}
GITEA_DOMAIN=${GITEA_DOMAIN}
GITEA_SECRET=${GITEA_SECRET}

# Drone Configuration
DRONE_DOMAIN=${DRONE_DOMAIN}
DRONE_RPC_SECRET=${DRONE_RPC_SECRET}
EOF

# Create docker-compose.yml with environment variables
log "Creating docker-compose.yml..."
cat > ${DATA_DIR}/docker-compose.yml << EOF
version: '3'

services:
  postgres:
    image: postgres:16-alpine
    container_name: postgres
    restart: always
    env_file:
      - docker-compose.env
    volumes:
      - ${DATA_DIR}/postgres:/var/lib/postgresql/data
    networks:
      - gitea-drone

  gitea:
    image: gitea/gitea:\${GITEA_VERSION}
    container_name: gitea
    restart: always
    depends_on:
      - postgres
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=postgres
      - GITEA__database__HOST=postgres:5432
      - GITEA__database__NAME=\${POSTGRES_DB}
      - GITEA__database__USER=\${POSTGRES_USER}
      - GITEA__database__PASSWD=\${POSTGRES_PASSWORD}
      - GITEA__security__SECRET_KEY=\${GITEA_SECRET}
      - GITEA__server__DOMAIN=\${GITEA_DOMAIN}
      - GITEA__server__ROOT_URL=https://\${GITEA_DOMAIN}/
      - GITEA__server__SSH_DOMAIN=\${GITEA_DOMAIN}
      - GITEA__server__PROTOCOL=https
      - GITEA__server__CERT_FILE=/data/certs/cert.pem
      - GITEA__server__KEY_FILE=/data/certs/key.pem
    env_file:
      - docker-compose.env
    volumes:
      - ${DATA_DIR}/gitea:/data
      - ${DATA_DIR}/certs/gitea-cert.pem:/data/certs/cert.pem
      - ${DATA_DIR}/certs/gitea-key.pem:/data/certs/key.pem
    ports:
      - "80:3000"
      - "443:3000"
      - "2222:22"
    networks:
      - gitea-drone

  drone-server:
    image: drone/drone:latest
    container_name: drone-server
    restart: always
    depends_on:
      - gitea
    environment:
      - DRONE_GITEA_SERVER=https://\${GITEA_DOMAIN}
      - DRONE_GITEA_CLIENT_ID=drone
      - DRONE_GITEA_CLIENT_SECRET=drone_secret
      - DRONE_RPC_SECRET=\${DRONE_RPC_SECRET}
      - DRONE_SERVER_HOST=\${DRONE_DOMAIN}
      - DRONE_SERVER_PROTO=https
      - DRONE_TLS_CERT=/data/certs/cert.pem
      - DRONE_TLS_KEY=/data/certs/key.pem
      - DRONE_USER_CREATE=username:\${GITEA_ADMIN_USER},admin:true
      - DRONE_DATABASE_DRIVER=postgres
      - DRONE_DATABASE_DATASOURCE=postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@postgres:5432/\${POSTGRES_DB}?sslmode=disable
    env_file:
      - docker-compose.env
    volumes:
      - ${DATA_DIR}/drone:/data
      - ${DATA_DIR}/certs/drone-cert.pem:/data/certs/cert.pem
      - ${DATA_DIR}/certs/drone-key.pem:/data/certs/key.pem
    ports:
      - "8080:80"
      - "8443:443"
    networks:
      - gitea-drone

  drone-runner:
    image: drone/drone-runner-docker:latest
    container_name: drone-runner
    restart: always
    depends_on:
      - drone-server
    environment:
      - DRONE_RPC_PROTO=https
      - DRONE_RPC_HOST=\${DRONE_DOMAIN}
      - DRONE_RPC_SECRET=\${DRONE_RPC_SECRET}
      - DRONE_RUNNER_NAME=drone-runner
      - DRONE_RUNNER_CAPACITY=2
      - DRONE_TMATE_ENABLED=true
    env_file:
      - docker-compose.env
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - gitea-drone

networks:
  gitea-drone:
    driver: bridge
EOF

# Create script for certificate renewal
log "Creating certificate renewal script..."
cat > ${DATA_DIR}/renew-certs.sh << EOF
#!/bin/bash

# Source environment variables
source ${DATA_DIR}/.env

# Renew certificates
certbot renew

# Copy updated certificates to data directory
cp /etc/letsencrypt/live/\${GITEA_DOMAIN}/fullchain.pem \${DATA_DIR}/certs/gitea-cert.pem
cp /etc/letsencrypt/live/\${GITEA_DOMAIN}/privkey.pem \${DATA_DIR}/certs/gitea-key.pem
cp /etc/letsencrypt/live/\${DRONE_DOMAIN}/fullchain.pem \${DATA_DIR}/certs/drone-cert.pem
cp /etc/letsencrypt/live/\${DRONE_DOMAIN}/privkey.pem \${DATA_DIR}/certs/drone-key.pem

# Restart containers to use new certificates
cd \${DATA_DIR}
docker-compose restart gitea drone-server
EOF

chmod +x ${DATA_DIR}/renew-certs.sh

# Add renewal script to crontab
log "Adding certificate renewal to crontab..."
(crontab -l 2>/dev/null || echo "") | grep -v "${DATA_DIR}/renew-certs.sh" | { cat; echo "0 3 * * * ${DATA_DIR}/renew-certs.sh"; } | crontab -

# Create a backup of the .env file
log "Creating backup of .env file..."
cp "$ENV_FILE" "${ENV_FILE}.backup"

# Start the services
log "Starting services..."
cd ${DATA_DIR}
docker-compose up -d

# Wait for Gitea to initialize
log "Waiting for Gitea to initialize..."
sleep 30

# Setup Gitea Admin and Drone OAuth application
log "Setting up Gitea admin and Drone OAuth application..."
GITEA_CONTAINER_ID=$(docker ps -qf "name=gitea")

# Create admin user in Gitea
docker exec -it ${GITEA_CONTAINER_ID} su git -c "/app/gitea/gitea admin user create --username ${GITEA_ADMIN_USER} --password ${GITEA_ADMIN_PASSWORD} --email ${GITEA_ADMIN_EMAIL} --admin --must-change-password=false"

# Create script for setting up OAuth application
cat > ${DATA_DIR}/setup-gitea-oauth.sh << EOF
#!/bin/bash

# Source environment variables
source ${DATA_DIR}/.env

# Log in to Gitea API to get session cookie
CSRF_TOKEN=\$(curl -s -c /tmp/gitea-cookie.txt "https://\${GITEA_DOMAIN}/user/login" | grep _csrf | sed -E 's/.*value="([^"]+)".*/\1/')

curl -s -b /tmp/gitea-cookie.txt -c /tmp/gitea-cookie.txt -X POST "https://\${GITEA_DOMAIN}/user/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "_csrf=\${CSRF_TOKEN}&user_name=\${GITEA_ADMIN_USER}&password=\${GITEA_ADMIN_PASSWORD}"

# Create OAuth2 application
curl -s -b /tmp/gitea-cookie.txt -X POST "https://\${GITEA_DOMAIN}/user/settings/applications/oauth2" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "application_name=drone&redirect_uris=https://\${DRONE_DOMAIN}/login&_csrf=\${CSRF_TOKEN}"

rm /tmp/gitea-cookie.txt
EOF

chmod +x ${DATA_DIR}/setup-gitea-oauth.sh

# Create update script for docker-compose.env
cat > ${DATA_DIR}/update-drone-config.sh << EOF
#!/bin/bash

# Source environment variables
source ${DATA_DIR}/.env

# Usage function
usage() {
    echo "Usage: \$0 <client_id> <client_secret>"
    echo "  client_id     - OAuth Client ID from Gitea"
    echo "  client_secret - OAuth Client Secret from Gitea"
    exit 1
}

# Check for required parameters
if [ \$# -ne 2 ]; then
    usage
fi

CLIENT_ID="\$1"
CLIENT_SECRET="\$2"

# Update docker-compose environment file
sed -i "s/DRONE_GITEA_CLIENT_ID=drone/DRONE_GITEA_CLIENT_ID=\${CLIENT_ID}/" ${DATA_DIR}/docker-compose.yml
sed -i "s/DRONE_GITEA_CLIENT_SECRET=drone_secret/DRONE_GITEA_CLIENT_SECRET=\${CLIENT_SECRET}/" ${DATA_DIR}/docker-compose.yml

# Restart Drone services
cd ${DATA_DIR}
docker-compose restart drone-server drone-runner

echo "Drone configuration updated with Gitea OAuth credentials."
EOF

chmod +x ${DATA_DIR}/update-drone-config.sh

log "======================================================================"
log "Installation complete!"
log ""
log "Gitea is available at: https://${GITEA_DOMAIN}"
log "Drone CI is available at: https://${DRONE_DOMAIN}"
log ""
log "Gitea admin credentials:"
log "  Username: ${GITEA_ADMIN_USER}"
log "  Password: ${GITEA_ADMIN_PASSWORD}"
log ""
log "IMPORTANT: Follow these steps to complete the setup:"
log ""
log "1. Run the OAuth setup script:"
log "   ${DATA_DIR}/setup-gitea-oauth.sh"
log ""
log "2. Go to Gitea > User Settings > Applications"
log "3. Find the 'drone' application and copy the Client ID and Client Secret"
log ""
log "4. Update Drone configuration with OAuth credentials:"
log "   ${DATA_DIR}/update-drone-config.sh <client_id> <client_secret>"
log ""
log "Configuration and credentials are stored in: ${ENV_FILE}"
log "A backup of your .env file is available at: ${ENV_FILE}.backup"
log ""
log "SECURITY NOTE: Please change the default admin password immediately!"
log "Certificate renewal will happen automatically via cron."
log "======================================================================"