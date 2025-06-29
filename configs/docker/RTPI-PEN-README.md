# RTPI-PEN: Red Team Penetration Testing Infrastructure

## Overview

RTPI-PEN is a comprehensive, containerized red team penetration testing infrastructure that provides a complete environment for security assessments, penetration testing, and red team operations. This deployment coordinates multiple specialized services into a unified platform accessible through web interfaces.

## Architecture

### Core Components

1. **Kasm Workspace Stack** - Web-accessible desktop environment
   - **kasm_proxy**: NGINX reverse proxy (Port 443)
   - **kasm_api**: API service for workspace management
   - **kasm_manager**: Workspace lifecycle management
   - **kasm_db**: PostgreSQL database for user/session data
   - **kasm_redis**: Redis for session caching
   - **kasm_agent**: Workspace agent for container management
   - **kasm_guac**: Apache Guacamole for remote desktop protocol
   - **kasm_share**: File sharing service

2. **RTPI-PEN Custom Desktop** - Specialized Kali Linux environment
   - Based on `kasmweb/kali-rolling-desktop:1.16.1`
   - Pre-installed penetration testing tools
   - Custom desktop shortcuts and welcome script
   - Integrated with Kasm infrastructure

3. **Supporting Services**
   - **Portainer**: Docker container management UI (Ports 8000, 9443)
   - **PowerShell Empire**: C2 framework (Ports 1337, 5000)
   - **SysReptor**: Professional penetration testing reporting (Port 9000)
   - **Node.js**: Development environment (Port 3500)

### Network Architecture

- **Kasm Network** (`172.18.0.0/16`): Main workspace network
- **Bridge Network** (`172.17.0.0/16`): General services network
- **SysReptor Network** (`172.20.0.0/16`): Isolated reporting network

## Pre-installed Tools

The RTPI-PEN desktop includes:

### Core Penetration Testing Tools
- **Metasploit Framework**: Exploitation framework
- **Nmap**: Network discovery and security auditing
- **Hashcat**: Advanced password recovery
- **Hydra**: Brute force attack tool
- **BloodHound**: Active Directory analysis
- **CrackMapExec**: Post-exploitation tool
- **Wireshark**: Network protocol analyzer

### Development & Scripting
- **Python 3** with pip and virtualenv
- **PowerShell**: Cross-platform automation
- **Java Development Kit**
- **Go programming language
- **Node.js and npm**

### System Tools
- **Git**: Version control
- **Docker**: Container management
- **Wine**: Windows application compatibility
- **ProxyChains**: Network proxy tool

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose Plugin
- Minimum 8GB RAM
- 50GB available disk space
- Linux host system (Ubuntu/Debian recommended)

### Deployment

1. **Clone or navigate to the configuration directory:**
   ```bash
   cd configs/docker
   ```

2. **Run the deployment script:**
   ```bash
   ./deploy-rtpi-pen.sh
   ```

3. **Wait for deployment to complete** (typically 10-15 minutes for first run)

4. **Access the services** using the URLs provided in the deployment output

### Manual Deployment

If you prefer manual deployment:

```bash
# Create necessary directories
sudo mkdir -p /mnt/docker/volumes/{rtpi-pen-data,rtpi-pen-tools,sysreptor-app-data,sysreptor-db-data,kasm_db_1.15.0,portainer_data}/_data

# Build custom image
docker build -t rtpi-pen:latest dockerfiles/RTPI-PEN/

# Deploy stack
docker compose -f "compose templates/rtpi-pen.docker-compose.yml" up -d
```

## Access Information

### Primary Interfaces

| Service | URL | Purpose |
|---------|-----|---------|
| **Kasm Workspace** | https://localhost:443 | Main workspace interface |
| **RTPI-PEN Desktop** | http://localhost:6901 | Direct desktop access |
| **Portainer** | https://localhost:9443 | Container management |
| **SysReptor** | http://localhost:9000 | Penetration testing reports |
| **PowerShell Empire** | http://localhost:1337 | C2 framework interface |

### Default Credentials

⚠️ **Change these before production use!**

- **RTPI-PEN VNC Password**: `rtpipassword`
- **SysReptor Database**: `sysreptor` / `sysreptorpassword`
- **Redis Password**: `sysreptorredispassword`

## Management Commands

The deployment script provides several management options:

```bash
# Deploy the complete infrastructure
./deploy-rtpi-pen.sh deploy

# Check service status
./deploy-rtpi-pen.sh status

# View service logs
./deploy-rtpi-pen.sh logs

# Stop all services
./deploy-rtpi-pen.sh stop

# Complete cleanup (removes all data)
./deploy-rtpi-pen.sh cleanup

# Show help
./deploy-rtpi-pen.sh help
```

## Volume Management

### Persistent Data Locations

All persistent data is stored in `/mnt/docker/volumes/`:

- `rtpi-pen-data/_data`: User home directory and settings
- `rtpi-pen-tools/_data`: Custom tools and scripts
- `sysreptor-app-data/_data`: Report templates and data
- `sysreptor-db-data/_data`: Report database
- `kasm_db_1.15.0/_data`: Workspace user data
- `portainer_data/_data`: Container management data

### Backup Strategy

```bash
# Backup all volumes
sudo tar -czf rtpi-pen-backup-$(date +%Y%m%d).tar.gz /mnt/docker/volumes/

# Restore from backup
sudo tar -xzf rtpi-pen-backup-YYYYMMDD.tar.gz -C /
```

## Security Considerations

### Network Security
- All services run in isolated Docker networks
- Only necessary ports are exposed to the host
- Internal service communication uses private networks

### Access Control
- Change default passwords immediately
- Use strong authentication for production deployments
- Consider implementing additional access controls (VPN, firewall rules)

### Container Security
- RTPI-PEN container runs with elevated privileges for tool functionality
- Regular security updates should be applied
- Monitor container logs for suspicious activity

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check for port usage
   sudo netstat -tulpn | grep -E ':(443|6901|9443|9000|1337)'
   
   # Stop conflicting services
   sudo systemctl stop apache2 nginx
   ```

2. **Permission Issues**
   ```bash
   # Fix volume permissions
   sudo chown -R 1000:1000 /mnt/docker/volumes/rtpi-pen-*/_data
   ```

3. **Memory Issues**
   ```bash
   # Check available memory
   free -h
   
   # Increase swap if needed
   sudo fallocate -l 4G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

### Service Health Checks

```bash
# Check all container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check specific service logs
docker logs rtpi-pen
docker logs kasm_proxy
docker logs sysreptor-app
```

## Customization

### Adding Tools to RTPI-PEN

Edit `dockerfiles/RTPI-PEN/Dockerfile` to add additional tools:

```dockerfile
# Add custom tools
RUN apt-get install -y your-tool-here

# Add Python packages
RUN pip3 install your-python-package

# Add custom scripts
COPY your-script.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/your-script.sh
```

### Modifying Network Configuration

Edit the networks section in `compose templates/rtpi-pen.docker-compose.yml`:

```yaml
networks:
  custom_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.0.0/16
          gateway: 172.21.0.1
```

## Performance Optimization

### Resource Allocation

For production deployments, consider:

- **CPU**: Minimum 4 cores, recommended 8+ cores
- **Memory**: Minimum 8GB, recommended 16GB+ RAM
- **Storage**: SSD recommended for better I/O performance
- **Network**: Gigabit network interface for large file transfers

### Container Limits

Add resource limits to services in the compose file:

```yaml
services:
  rtpi-pen:
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '2.0'
          memory: 4G
```

## Integration with External Tools

### CI/CD Integration

The deployment can be integrated with CI/CD pipelines:

```bash
# Automated deployment
./deploy-rtpi-pen.sh deploy
./deploy-rtpi-pen.sh status

# Run tests
curl -f https://localhost:443 || exit 1
curl -f http://localhost:6901 || exit 1
```

### Monitoring Integration

Consider integrating with monitoring solutions:
- Prometheus for metrics collection
- Grafana for visualization
- ELK stack for log aggregation

## Support and Contributing

### Getting Help

1. Check the troubleshooting section above
2. Review container logs for error messages
3. Ensure all prerequisites are met
4. Verify network connectivity and port availability

### Contributing

To contribute improvements:
1. Test changes in a development environment
2. Update documentation as needed
3. Follow security best practices
4. Submit detailed change descriptions

## License and Disclaimer

This infrastructure is designed for authorized security testing and educational purposes only. Users are responsible for ensuring compliance with applicable laws and regulations. The tools included are powerful and should be used responsibly.

---

**Version**: 1.0  
**Last Updated**: 2025-06-29  
**Compatibility**: Docker Engine 20.10+, Docker Compose Plugin
