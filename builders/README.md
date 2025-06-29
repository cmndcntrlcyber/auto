# Builders - Build Automation & CI/CD Scripts

This directory contains automation scripts for building, deploying, and managing infrastructure components. These tools are designed to streamline the setup of development environments, CI/CD pipelines, and various services.

## 📁 Directory Contents

### 🔧 Build Scripts

- **`build-automation.sh`** - Comprehensive Gitea and Drone CI installation with SSL
- **`build-flask.sh`** - Flask application deployment automation
- **`build-llm.sh`** - Large Language Model setup and configuration
- **`build-merlin.sh`** - Merlin framework deployment
- **`flask-app.sh`** - Flask application builder
- **`supabase.sh`** - Supabase backend setup

### 📦 Code Snippets

The `snippets/` directory contains reusable code components:

#### Python Classes (`snippets/py/`)
- **`class-SecureExecutionEnvironment`** - Secure command execution with threading
- **`class-WebAgent`** - Web automation and interaction utilities

## 🚀 Quick Start

### Prerequisites

- **Root/Administrator access** for system-level installations
- **Docker and Docker Compose** for containerized deployments
- **Python 3.8+** for Python-based tools
- **Bash shell** (Linux/macOS/WSL)

### Basic Usage

1. **Make scripts executable:**
   ```bash
   chmod +x *.sh
   ```

2. **Run a build script:**
   ```bash
   sudo ./build-automation.sh
   ```

3. **Use Python snippets:**
   ```python
   from snippets.py.class-SecureExecutionEnvironment import SecureExecutionEnvironment
   
   executor = SecureExecutionEnvironment(['ls', '-la'])
   executor.start()
   executor.wait_for_completion()
   result = executor.get_output()
   ```

## 🛠️ Detailed Tool Documentation

### build-automation.sh

**Purpose**: Automated installation of Gitea (Git service) and Drone CI with SSL certificates via Cloudflare.

**Features**:
- Automated SSL certificate generation using Let's Encrypt and Cloudflare DNS
- Docker-based deployment with PostgreSQL backend
- Comprehensive logging and error handling
- Environment-based configuration management
- Automatic certificate renewal setup

**Usage**:
```bash
# Basic installation
sudo ./build-automation.sh

# The script will create a .env file for configuration
# Edit /opt/gitea-drone/.env with your settings before running
```

**Configuration**:
- Cloudflare API key for DNS challenges
- Domain names for Gitea and Drone
- Admin credentials
- Database passwords (auto-generated)

**Post-Installation**:
1. Access Gitea at your configured domain
2. Set up OAuth application for Drone integration
3. Configure Drone with OAuth credentials

### SecureExecutionEnvironment Class

**Purpose**: Thread-safe command execution with timeout handling and output capture.

**Features**:
- Non-blocking command execution
- Configurable timeouts
- Secure process isolation
- Comprehensive error handling
- Output capture and analysis

**Example Usage**:
```python
from snippets.py.class-SecureExecutionEnvironment import SecureExecutionEnvironment

# Basic command execution
executor = SecureExecutionEnvironment(['ping', '-c', '3', 'google.com'])
executor.start()

# Wait for completion with timeout
if executor.wait_for_completion(timeout=30):
    result = executor.get_output()
    print(f"Status: {executor.get_status()}")
    print(f"Output: {result['stdout']}")
    print(f"Execution time: {result['execution_time']:.2f}s")
else:
    print("Command timed out")
    executor.force_stop()

# Advanced usage with custom environment
executor = SecureExecutionEnvironment(
    command=['python3', 'script.py'],
    timeout=60,
    working_directory='/path/to/project',
    environment_vars={'PYTHONPATH': '/custom/path'},
    capture_output=True
)
```

### Flask Application Builders

**Purpose**: Automated Flask application deployment and configuration.

**Features**:
- Virtual environment setup
- Dependency installation
- Database initialization
- SSL configuration
- Production-ready deployment

**Usage**:
```bash
# Deploy Flask application
./build-flask.sh

# Or use the alternative script
./flask-app.sh
```

## 🔒 Security Considerations

### Build Scripts
- **Run with appropriate privileges**: Some scripts require root access
- **Review configurations**: Always review generated configuration files
- **Secure credentials**: Use strong passwords and API keys
- **Network security**: Configure firewalls and access controls

### Code Snippets
- **Input validation**: Always validate command inputs
- **Process isolation**: Use secure execution environments
- **Resource limits**: Implement timeouts and resource constraints
- **Error handling**: Properly handle and log errors

## 📋 Configuration Examples

### Environment Configuration (.env)
```bash
# Cloudflare API Key
CLOUDFLARE_API_KEY=your-api-key-here

# Domain Configuration
GITEA_DOMAIN=git.yourdomain.com
DRONE_DOMAIN=ci.yourdomain.com

# Admin Credentials
GITEA_ADMIN_USER=admin
GITEA_ADMIN_PASSWORD=secure-password
GITEA_ADMIN_EMAIL=admin@yourdomain.com

# Installation Directory
DATA_DIR=/opt/gitea-drone
```

### Docker Compose Override
```yaml
# docker-compose.override.yml
version: '3'
services:
  gitea:
    environment:
      - GITEA__server__DISABLE_REGISTRATION=true
      - GITEA__service__REQUIRE_SIGNIN_VIEW=true
    volumes:
      - ./custom/app.ini:/data/gitea/conf/app.ini
```

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   chmod +x *.sh
   sudo ./script-name.sh
   ```

2. **Docker Not Running**
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

3. **SSL Certificate Issues**
   - Verify Cloudflare API key permissions
   - Check DNS propagation
   - Review certificate logs in `/var/log/letsencrypt/`

4. **Port Conflicts**
   - Check for existing services on ports 80, 443, 8080, 8443
   - Modify docker-compose.yml port mappings if needed

### Log Locations
- **Build logs**: `/var/log/build-automation.log`
- **Docker logs**: `docker-compose logs -f`
- **Certificate logs**: `/var/log/letsencrypt/`

## 🔄 Maintenance

### Regular Tasks
1. **Certificate renewal**: Automated via cron job
2. **Backup configurations**: Regular backup of .env and data directories
3. **Update containers**: `docker-compose pull && docker-compose up -d`
4. **Monitor logs**: Regular log review for issues

### Backup Script Example
```bash
#!/bin/bash
BACKUP_DIR="/backup/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup configuration
cp -r /opt/gitea-drone/.env "$BACKUP_DIR/"
cp -r /opt/gitea-drone/docker-compose.yml "$BACKUP_DIR/"

# Backup data (with Docker stopped)
docker-compose -f /opt/gitea-drone/docker-compose.yml down
tar -czf "$BACKUP_DIR/data.tar.gz" /opt/gitea-drone/
docker-compose -f /opt/gitea-drone/docker-compose.yml up -d
```

## 🤝 Contributing

When adding new build scripts:

1. **Follow naming conventions**: `build-<service>.sh`
2. **Include comprehensive logging**: Use consistent log formatting
3. **Add error handling**: Proper exit codes and cleanup
4. **Document configuration**: Include example configurations
5. **Test thoroughly**: Test on clean systems
6. **Update documentation**: Add to this README

### Script Template
```bash
#!/bin/bash
set -e

# Color codes for logging
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check prerequisites
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
fi

# Your build logic here
log "Starting build process..."

# Cleanup on exit
trap 'log "Build completed"' EXIT
```

---

**Note**: Always test build scripts in isolated environments before using in production. Ensure you have proper backups and rollback procedures in place.
