#!/bin/bash

"""
Flask Application Deployment Script

An optimized and secure script for deploying Flask applications with proper
error handling, logging, and security considerations. This script replaces
the basic version from random/replace.sh with enhanced functionality.

Features:
- Secure file operations with validation
- Comprehensive logging and error handling
- Service management with proper checks
- Backup and rollback capabilities
- Configuration validation

Author: Security Automation Team
Version: 2.0.0
License: MIT
"""

# Source shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../shared/install-functions.sh"

# Configuration
readonly DEFAULT_SOURCE_DIR="/opt"
readonly DEFAULT_TARGET_DIR="/var/www/apps"
readonly BACKUP_DIR="/var/backups/flask-apps"

# Application configuration
declare -A APP_CONFIGS=(
    ["login"]="/opt/login"
    ["register"]="/opt/register"
)

# Validation functions
validate_source_directory() {
    local app_name="$1"
    local source_dir="$2"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "Source directory does not exist: $source_dir"
        return 1
    fi
    
    if [[ ! -r "$source_dir" ]]; then
        log_error "Source directory is not readable: $source_dir"
        return 1
    fi
    
    log_success "Source directory validated: $source_dir"
    return 0
}

validate_target_directory() {
    local target_dir="$1"
    
    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        log_info "Creating target directory: $target_dir"
        if ! sudo mkdir -p "$target_dir"; then
            log_error "Failed to create target directory: $target_dir"
            return 1
        fi
    fi
    
    if [[ ! -w "$target_dir" ]]; then
        log_error "Target directory is not writable: $target_dir"
        return 1
    fi
    
    log_success "Target directory validated: $target_dir"
    return 0
}

# Backup functions
create_backup() {
    local app_name="$1"
    local target_path="$2"
    
    if [[ ! -d "$target_path" ]]; then
        log_info "No existing deployment to backup for: $app_name"
        return 0
    fi
    
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/${app_name}_${backup_timestamp}"
    
    log_info "Creating backup: $backup_path"
    
    if ! sudo mkdir -p "$BACKUP_DIR"; then
        log_error "Failed to create backup directory: $BACKUP_DIR"
        return 1
    fi
    
    if ! sudo cp -r "$target_path" "$backup_path"; then
        log_error "Failed to create backup: $backup_path"
        return 1
    fi
    
    log_success "Backup created: $backup_path"
    echo "$backup_path"  # Return backup path for potential rollback
    return 0
}

restore_backup() {
    local backup_path="$1"
    local target_path="$2"
    
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup directory does not exist: $backup_path"
        return 1
    fi
    
    log_info "Restoring from backup: $backup_path"
    
    # Remove current deployment
    if [[ -d "$target_path" ]]; then
        sudo rm -rf "$target_path"
    fi
    
    # Restore from backup
    if ! sudo cp -r "$backup_path" "$target_path"; then
        log_error "Failed to restore from backup"
        return 1
    fi
    
    log_success "Successfully restored from backup"
    return 0
}

# Deployment functions
deploy_application() {
    local app_name="$1"
    local source_dir="$2"
    local target_dir="$3"
    
    log_step "Deploying application: $app_name"
    
    # Validate directories
    if ! validate_source_directory "$app_name" "$source_dir"; then
        return 1
    fi
    
    if ! validate_target_directory "$target_dir"; then
        return 1
    fi
    
    local target_path="$target_dir/$app_name"
    
    # Create backup if target exists
    local backup_path
    backup_path=$(create_backup "$app_name" "$target_path")
    local backup_created=$?
    
    # Deploy application
    log_info "Copying application files..."
    if ! sudo cp -r "$source_dir" "$target_path"; then
        log_error "Failed to copy application files"
        
        # Restore backup if deployment failed and backup exists
        if [[ $backup_created -eq 0 && -n "$backup_path" ]]; then
            log_info "Attempting to restore from backup..."
            restore_backup "$backup_path" "$target_path"
        fi
        
        return 1
    fi
    
    # Set proper permissions
    log_info "Setting proper permissions..."
    sudo chown -R www-data:www-data "$target_path"
    sudo chmod -R 755 "$target_path"
    
    # Set Flask app environment variable
    log_info "Configuring Flask environment..."
    local flask_app_path="$target_path/${app_name}.py"
    
    if [[ -f "$flask_app_path" ]]; then
        export FLASK_APP="$flask_app_path"
        log_success "Flask app configured: $flask_app_path"
    else
        log_warn "Flask app file not found: $flask_app_path"
    fi
    
    log_success "Application deployed successfully: $app_name"
    return 0
}

# Service management
restart_web_services() {
    log_step "Restarting web services..."
    
    # Check if Apache is installed and running
    if check_command "apache2"; then
        log_info "Reloading Apache configuration..."
        if ! sudo systemctl reload apache2; then
            log_warn "Failed to reload Apache, attempting restart..."
            if ! sudo systemctl restart apache2; then
                log_error "Failed to restart Apache"
                return 1
            fi
        fi
        log_success "Apache restarted successfully"
    else
        log_warn "Apache2 not found, skipping Apache restart"
    fi
    
    # Check if Nginx is installed and running
    if check_command "nginx"; then
        log_info "Reloading Nginx configuration..."
        if ! sudo systemctl reload nginx; then
            log_warn "Failed to reload Nginx, attempting restart..."
            if ! sudo systemctl restart nginx; then
                log_error "Failed to restart Nginx"
                return 1
            fi
        fi
        log_success "Nginx restarted successfully"
    fi
    
    return 0
}

# Health check functions
verify_deployment() {
    local app_name="$1"
    local target_path="$2"
    
    log_step "Verifying deployment: $app_name"
    
    # Check if application directory exists
    if [[ ! -d "$target_path" ]]; then
        log_error "Application directory not found: $target_path"
        return 1
    fi
    
    # Check if main application file exists
    local main_file="$target_path/${app_name}.py"
    if [[ ! -f "$main_file" ]]; then
        log_warn "Main application file not found: $main_file"
    else
        log_success "Main application file found: $main_file"
    fi
    
    # Check permissions
    local owner=$(stat -c '%U:%G' "$target_path")
    if [[ "$owner" == "www-data:www-data" ]]; then
        log_success "Correct ownership: $owner"
    else
        log_warn "Unexpected ownership: $owner (expected www-data:www-data)"
    fi
    
    log_success "Deployment verification completed"
    return 0
}

# Main deployment function
deploy_flask_applications() {
    local apps_to_deploy=("$@")
    
    log_info "Starting Flask application deployment..."
    log_info "Applications to deploy: ${apps_to_deploy[*]}"
    
    # If no specific apps provided, deploy all configured apps
    if [[ ${#apps_to_deploy[@]} -eq 0 ]]; then
        apps_to_deploy=($(printf '%s\n' "${!APP_CONFIGS[@]}"))
        log_info "No specific apps provided, deploying all: ${apps_to_deploy[*]}"
    fi
    
    local failed_deployments=()
    local successful_deployments=()
    
    # Deploy each application
    for app_name in "${apps_to_deploy[@]}"; do
        if [[ -n "${APP_CONFIGS[$app_name]}" ]]; then
            local source_dir="${APP_CONFIGS[$app_name]}"
            local target_path="$DEFAULT_TARGET_DIR/$app_name"
            
            if deploy_application "$app_name" "$source_dir" "$DEFAULT_TARGET_DIR"; then
                successful_deployments+=("$app_name")
                verify_deployment "$app_name" "$target_path"
            else
                failed_deployments+=("$app_name")
            fi
        else
            log_error "Unknown application: $app_name"
            failed_deployments+=("$app_name")
        fi
    done
    
    # Restart web services if any deployments were successful
    if [[ ${#successful_deployments[@]} -gt 0 ]]; then
        restart_web_services
    fi
    
    # Report results
    log_info "Deployment Summary:"
    log_info "  Successful: ${successful_deployments[*]:-none}"
    log_info "  Failed: ${failed_deployments[*]:-none}"
    
    if [[ ${#failed_deployments[@]} -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

# Configuration management
add_application_config() {
    local app_name="$1"
    local source_dir="$2"
    
    if [[ -z "$app_name" || -z "$source_dir" ]]; then
        log_error "Usage: add_application_config <app_name> <source_dir>"
        return 1
    fi
    
    APP_CONFIGS["$app_name"]="$source_dir"
    log_success "Added application configuration: $app_name -> $source_dir"
}

list_application_configs() {
    log_info "Configured applications:"
    for app_name in "${!APP_CONFIGS[@]}"; do
        log_info "  $app_name: ${APP_CONFIGS[$app_name]}"
    done
}

# Usage information
show_usage() {
    cat << EOF
Flask Application Deployer v2.0.0

Usage: $0 [OPTIONS] [APP_NAMES...]

Options:
  -h, --help              Show this help message
  -l, --list              List configured applications
  -a, --add NAME DIR      Add application configuration
  -b, --backup-dir DIR    Set backup directory (default: $BACKUP_DIR)
  -t, --target-dir DIR    Set target directory (default: $DEFAULT_TARGET_DIR)
  -v, --verbose           Enable verbose logging

Examples:
  $0                      Deploy all configured applications
  $0 login register       Deploy specific applications
  $0 -a myapp /opt/myapp  Add new application configuration
  $0 -l                   List all configured applications

Configured Applications:
EOF
    for app_name in "${!APP_CONFIGS[@]}"; do
        echo "  $app_name: ${APP_CONFIGS[$app_name]}"
    done
}

# Main execution
main() {
    # Setup error handling
    setup_error_handling
    
    # Parse command line arguments
    local apps_to_deploy=()
    local show_help=false
    local list_configs=false
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help=true
                shift
                ;;
            -l|--list)
                list_configs=true
                shift
                ;;
            -a|--add)
                if [[ $# -lt 3 ]]; then
                    log_error "Option --add requires app name and source directory"
                    exit 1
                fi
                add_application_config "$2" "$3"
                shift 3
                ;;
            -b|--backup-dir)
                if [[ $# -lt 2 ]]; then
                    log_error "Option --backup-dir requires directory path"
                    exit 1
                fi
                BACKUP_DIR="$2"
                shift 2
                ;;
            -t|--target-dir)
                if [[ $# -lt 2 ]]; then
                    log_error "Option --target-dir requires directory path"
                    exit 1
                fi
                DEFAULT_TARGET_DIR="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                apps_to_deploy+=("$1")
                shift
                ;;
        esac
    done
    
    # Handle help and list options
    if [[ "$show_help" == true ]]; then
        show_usage
        exit 0
    fi
    
    if [[ "$list_configs" == true ]]; then
        list_application_configs
        exit 0
    fi
    
    # Check prerequisites
    if ! check_sudo_privileges; then
        exit 1
    fi
    
    # Display system information if verbose
    if [[ "$verbose" == true ]]; then
        get_system_info
    fi
    
    # Perform deployment
    log_info "Flask Application Deployer v2.0.0"
    log_info "Target directory: $DEFAULT_TARGET_DIR"
    log_info "Backup directory: $BACKUP_DIR"
    
    if deploy_flask_applications "${apps_to_deploy[@]}"; then
        log_success "All deployments completed successfully!"
        exit 0
    else
        log_error "Some deployments failed. Check logs for details."
        exit 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
