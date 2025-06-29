#!/bin/bash

# RTPI-PEN Configuration Validation Script
# This script validates the Docker configuration files before deployment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration files
COMPOSE_FILE="compose templates/rtpi-pen.docker-compose.yml"
DOCKERFILE="dockerfiles/RTPI-PEN/Dockerfile"
DEPLOY_SCRIPT="deploy-rtpi-pen.sh"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[VALIDATE]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Validation functions
validate_compose_file() {
    print_status "Validating Docker Compose file..."
    
    if [ ! -f "${COMPOSE_FILE}" ]; then
        print_error "Docker Compose file not found: ${COMPOSE_FILE}"
        return 1
    fi
    
    # Check if docker-compose can parse the file
    if docker compose -f "${COMPOSE_FILE}" config > /dev/null 2>&1; then
        print_success "Docker Compose file syntax is valid"
    else
        print_error "Docker Compose file has syntax errors"
        docker compose -f "${COMPOSE_FILE}" config
        return 1
    fi
    
    # Check for required services
    required_services=("rtpi-pen" "kasm_proxy" "portainer" "sysreptor-app")
    for service in "${required_services[@]}"; do
        if docker compose -f "${COMPOSE_FILE}" config | grep -q "^  ${service}:"; then
            print_success "Required service '${service}' found"
        else
            print_error "Required service '${service}' not found"
            return 1
        fi
    done
    
    # Check for network conflicts
    networks=$(docker compose -f "${COMPOSE_FILE}" config | grep -A 5 "^networks:" | grep -E "^\s+[a-zA-Z]" | awk '{print $1}' | tr -d ':')
    for network in $networks; do
        if docker network ls | grep -q "$network"; then
            print_warning "Network '$network' already exists - may cause conflicts"
        else
            print_success "Network '$network' is available"
        fi
    done
}

validate_dockerfile() {
    print_status "Validating Dockerfile..."
    
    if [ ! -f "${DOCKERFILE}" ]; then
        print_error "Dockerfile not found: ${DOCKERFILE}"
        return 1
    fi
    
    # Check Dockerfile syntax
    if docker build --dry-run -f "${DOCKERFILE}" dockerfiles/RTPI-PEN/ > /dev/null 2>&1; then
        print_success "Dockerfile syntax is valid"
    else
        print_error "Dockerfile has syntax errors"
        return 1
    fi
    
    # Check for required components
    if grep -q "FROM kasmweb/kali-rolling-desktop" "${DOCKERFILE}"; then
        print_success "Base image specified correctly"
    else
        print_error "Base image not found or incorrect"
        return 1
    fi
    
    if grep -q "apt-get install.*metasploit-framework" "${DOCKERFILE}"; then
        print_success "Metasploit installation found"
    else
        print_warning "Metasploit installation not found in Dockerfile"
    fi
    
    if grep -q "pip3 install" "${DOCKERFILE}"; then
        print_success "Python packages installation found"
    else
        print_warning "Python packages installation not found"
    fi
}

validate_deployment_script() {
    print_status "Validating deployment script..."
    
    if [ ! -f "${DEPLOY_SCRIPT}" ]; then
        print_error "Deployment script not found: ${DEPLOY_SCRIPT}"
        return 1
    fi
    
    if [ ! -x "${DEPLOY_SCRIPT}" ]; then
        print_error "Deployment script is not executable"
        return 1
    fi
    
    # Check for required functions
    required_functions=("check_prerequisites" "deploy_stack" "check_health")
    for func in "${required_functions[@]}"; do
        if grep -q "^${func}()" "${DEPLOY_SCRIPT}"; then
            print_success "Function '${func}' found in deployment script"
        else
            print_error "Function '${func}' not found in deployment script"
            return 1
        fi
    done
}

validate_system_requirements() {
    print_status "Validating system requirements..."
    
    # Check Docker
    if command -v docker &> /dev/null; then
        docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        print_success "Docker found (version: ${docker_version})"
    else
        print_error "Docker not found - please install Docker"
        return 1
    fi
    
    # Check Docker Compose
    if docker compose version &> /dev/null; then
        compose_version=$(docker compose version --short 2>/dev/null || echo "unknown")
        print_success "Docker Compose plugin found (version: ${compose_version})"
    else
        print_error "Docker Compose plugin not found"
        return 1
    fi
    
    # Check available memory
    available_mem=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    if [ "$available_mem" -gt 4096 ]; then
        print_success "Sufficient memory available (${available_mem}MB)"
    else
        print_warning "Low memory available (${available_mem}MB) - recommend 8GB+"
    fi
    
    # Check available disk space
    available_disk=$(df -BG . | awk 'NR==2{print $4}' | tr -d 'G')
    if [ "$available_disk" -gt 20 ]; then
        print_success "Sufficient disk space available (${available_disk}GB)"
    else
        print_warning "Low disk space available (${available_disk}GB) - recommend 50GB+"
    fi
}

validate_port_availability() {
    print_status "Validating port availability..."
    
    # Required ports
    required_ports=(443 6901 8000 9443 9000 1337 5000 3500 4444 8080)
    
    for port in "${required_ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":${port} " || ss -tuln 2>/dev/null | grep -q ":${port} "; then
            print_warning "Port ${port} is already in use"
        else
            print_success "Port ${port} is available"
        fi
    done
}

validate_docker_permissions() {
    print_status "Validating Docker permissions..."
    
    if docker ps &> /dev/null; then
        print_success "Docker permissions are correct"
    else
        print_error "Cannot access Docker - check permissions or run as root"
        return 1
    fi
}

# Main validation function
main() {
    echo "RTPI-PEN Configuration Validation"
    echo "=================================="
    echo ""
    
    validation_failed=0
    
    # Run all validations
    validate_compose_file || validation_failed=1
    echo ""
    
    validate_dockerfile || validation_failed=1
    echo ""
    
    validate_deployment_script || validation_failed=1
    echo ""
    
    validate_system_requirements || validation_failed=1
    echo ""
    
    validate_port_availability || validation_failed=1
    echo ""
    
    validate_docker_permissions || validation_failed=1
    echo ""
    
    # Summary
    if [ $validation_failed -eq 0 ]; then
        print_success "All validations passed! Ready for deployment."
        echo ""
        echo "To deploy RTPI-PEN infrastructure, run:"
        echo "  ./deploy-rtpi-pen.sh"
        exit 0
    else
        print_error "Some validations failed. Please fix the issues before deployment."
        exit 1
    fi
}

# Run main function
main "$@"
