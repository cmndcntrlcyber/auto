#!/bin/bash

# RTPI-PEN Comprehensive Deployment Script
# This script coordinates the deployment of the complete Red Team Penetration Testing Infrastructure

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="compose templates/rtpi-pen.docker-compose.yml"
DOCKERFILE_PATH="dockerfiles/RTPI-PEN"
VOLUMES_BASE="/mnt/docker/volumes"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available. Please install Docker Compose plugin."
        exit 1
    fi
    
    # Check if running as root or with docker group
    if ! docker ps &> /dev/null; then
        print_error "Cannot access Docker. Please run as root or add user to docker group."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    # Create volume directories
    sudo mkdir -p "${VOLUMES_BASE}/rtpi-pen-data/_data"
    sudo mkdir -p "${VOLUMES_BASE}/rtpi-pen-tools/_data"
    sudo mkdir -p "${VOLUMES_BASE}/sysreptor-app-data/_data"
    sudo mkdir -p "${VOLUMES_BASE}/sysreptor-db-data/_data"
    sudo mkdir -p "${VOLUMES_BASE}/sysreptor-caddy-data/_data"
    sudo mkdir -p "${VOLUMES_BASE}/kasm_db_1.15.0/_data"
    sudo mkdir -p "${VOLUMES_BASE}/portainer_data/_data"
    
    # Set proper permissions
    sudo chown -R 1000:1000 "${VOLUMES_BASE}/rtpi-pen-data/_data"
    sudo chown -R 1000:1000 "${VOLUMES_BASE}/rtpi-pen-tools/_data"
    
    print_success "Directories created successfully"
}

# Function to build custom images
build_images() {
    print_status "Building RTPI-PEN custom image..."
    
    cd "$(dirname "$0")"
    
    # Build the RTPI-PEN image
    docker build -t rtpi-pen:latest "${DOCKERFILE_PATH}"
    
    print_success "Custom images built successfully"
}

# Function to deploy the stack
deploy_stack() {
    print_status "Deploying RTPI-PEN infrastructure..."
    
    cd "$(dirname "$0")"
    
    # Deploy the complete stack
    docker compose -f "${COMPOSE_FILE}" up -d
    
    print_success "RTPI-PEN infrastructure deployed successfully"
}

# Function to check service health
check_health() {
    print_status "Checking service health..."
    
    # Wait for services to start
    sleep 30
    
    # Check critical services
    services=("kasm_db" "kasm_api" "kasm_proxy" "portainer" "sysreptor-app" "rtpi-pen")
    
    for service in "${services[@]}"; do
        if docker ps --filter "name=${service}" --filter "status=running" | grep -q "${service}"; then
            print_success "${service} is running"
        else
            print_warning "${service} is not running properly"
        fi
    done
}

# Function to display access information
display_access_info() {
    print_status "Deployment completed! Access information:"
    echo ""
    echo -e "${GREEN}=== RTPI-PEN Access URLs ===${NC}"
    echo -e "${BLUE}Kasm Workspace (Main Interface):${NC} https://localhost:443"
    echo -e "${BLUE}RTPI-PEN Desktop:${NC} http://localhost:6901"
    echo -e "${BLUE}Portainer (Container Management):${NC} https://localhost:9443"
    echo -e "${BLUE}SysReptor (Reporting):${NC} http://localhost:9000"
    echo -e "${BLUE}PowerShell Empire (C2):${NC} http://localhost:1337"
    echo ""
    echo -e "${GREEN}=== Default Credentials ===${NC}"
    echo -e "${BLUE}RTPI-PEN VNC Password:${NC} rtpipassword"
    echo -e "${BLUE}SysReptor Database:${NC} sysreptor / sysreptorpassword"
    echo ""
    echo -e "${GREEN}=== Network Information ===${NC}"
    echo -e "${BLUE}Kasm Network:${NC} 172.18.0.0/16"
    echo -e "${BLUE}Bridge Network:${NC} 172.17.0.0/16"
    echo -e "${BLUE}SysReptor Network:${NC} 172.20.0.0/16"
    echo ""
    echo -e "${YELLOW}Note: Change default passwords before production use!${NC}"
}

# Function to show logs
show_logs() {
    print_status "Showing recent logs for all services..."
    cd "$(dirname "$0")"
    docker compose -f "${COMPOSE_FILE}" logs --tail=50
}

# Function to stop the stack
stop_stack() {
    print_status "Stopping RTPI-PEN infrastructure..."
    cd "$(dirname "$0")"
    docker compose -f "${COMPOSE_FILE}" down
    print_success "RTPI-PEN infrastructure stopped"
}

# Function to clean up everything
cleanup() {
    print_warning "This will remove all containers, images, and volumes. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Cleaning up RTPI-PEN infrastructure..."
        cd "$(dirname "$0")"
        docker compose -f "${COMPOSE_FILE}" down -v --rmi all
        docker system prune -f
        print_success "Cleanup completed"
    else
        print_status "Cleanup cancelled"
    fi
}

# Main function
main() {
    case "${1:-deploy}" in
        "deploy")
            check_prerequisites
            create_directories
            build_images
            deploy_stack
            check_health
            display_access_info
            ;;
        "stop")
            stop_stack
            ;;
        "logs")
            show_logs
            ;;
        "status")
            check_health
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            echo "RTPI-PEN Deployment Script"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  deploy    Deploy the complete RTPI-PEN infrastructure (default)"
            echo "  stop      Stop all services"
            echo "  logs      Show logs from all services"
            echo "  status    Check service health status"
            echo "  cleanup   Remove all containers, images, and volumes"
            echo "  help      Show this help message"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
