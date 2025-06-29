#!/bin/bash

"""
Fresh Kali Linux Setup Script

Comprehensive setup script for a fresh Kali Linux installation with security tools,
development environments, and penetration testing utilities. This script automates
the installation and configuration of essential tools for cybersecurity professionals.

Features:
- Organized directory structure for security testing
- Essential security tool repositories
- Development environment setup (Python, Rust, Go, Node.js)
- Docker and containerization tools
- Browser and GUI applications
- Custom aliases and shortcuts

Author: Security Automation Team
Version: 2.0.0
License: MIT

SECURITY WARNING: This script installs penetration testing tools.
Ensure you have proper authorization before using these tools in any environment.
"""

set -e  # Exit on any error

# Color codes for better output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Progress tracking
TOTAL_STEPS=8
CURRENT_STEP=0

show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "${PURPLE}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} $1"
}

# Error handling
cleanup_on_error() {
    log_error "Script failed at step ${CURRENT_STEP}. Cleaning up..."
    # Add any cleanup operations here
    exit 1
}

trap cleanup_on_error ERR

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons."
        log_info "Please run as a regular user. The script will use sudo when needed."
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    log_step "Checking system requirements..."
    
    # Check if running on Kali Linux
    if ! grep -q "Kali" /etc/os-release 2>/dev/null; then
        log_warn "This script is designed for Kali Linux. Proceeding anyway..."
    fi
    
    # Check available disk space (minimum 10GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 10485760 ]]; then  # 10GB in KB
        log_error "Insufficient disk space. At least 10GB free space required."
        exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "No internet connection detected. Please check your network."
        exit 1
    fi
    
    log_success "System requirements check passed"
}

# Create organized directory structure
create_directory_structure() {
    show_progress "Creating organized directory structure..."
    
    # Define directory structure
    local directories=(
        "$HOME/security"
        "$HOME/security/vpns"
        "$HOME/security/files"
        "$HOME/security/github"
        "$HOME/security/recon"
        "$HOME/security/recon/wordlists"
        "$HOME/security/targets"
        "$HOME/security/targets/htb"
        "$HOME/security/targets/thm"
        "$HOME/security/targets/bounty"
        "$HOME/security/targets/bounty/h1"
        "$HOME/security/targets/bounty/bugcrowd"
        "$HOME/security/payloads"
        "$HOME/security/post"
        "$HOME/security/post/win"
        "$HOME/security/engaged"
        "$HOME/security/engaged/admin"
        "$HOME/security/engaged/osint"
        "$HOME/security/engaged/recon"
        "$HOME/security/engaged/targets"
        "$HOME/security/engaged/targets/domain"
        "$HOME/security/engaged/targets/domain/hostname"
        "$HOME/security/engaged/targets/domain/exfil"
        "$HOME/security/engaged/targets/domain/hostname/exfil"
        "$HOME/security/engaged/screenshots"
        "$HOME/security/engaged/payloads"
        "$HOME/security/engaged/payloads/entry"
        "$HOME/security/engaged/payloads/privesc"
        "$HOME/security/engaged/payloads/persistence"
        "$HOME/security/engaged/logs"
        "/var/log/session"
    )
    
    # Create directories with proper permissions
    for dir in "${directories[@]}"; do
        if [[ "$dir" == "/var/log/session" ]]; then
            sudo mkdir -p "$dir"
            sudo chown $USER:$USER "$dir"
        else
            mkdir -p "$dir"
        fi
        log_info "Created directory: $dir"
    done
    
    # Create README file for the security directory
    cat > "$HOME/security/README.md" << 'EOF'
# Security Testing Directory Structure

This directory contains organized folders for security testing activities.

## Directory Structure

- **vpns/**: VPN configurations and connection files
- **files/**: General files and documents
- **github/**: Cloned security tools and repositories
- **recon/**: Reconnaissance tools and results
- **targets/**: Target-specific information and results
- **payloads/**: Exploit payloads and scripts
- **post/**: Post-exploitation tools and scripts
- **engaged/**: Active engagement materials and results

## Usage Guidelines

1. Keep all testing materials organized in appropriate directories
2. Document all activities in the respective folders
3. Maintain proper file naming conventions
4. Regularly backup important findings
5. Follow responsible disclosure practices

## Security Reminder

All tools and techniques should only be used on systems you own or have explicit permission to test.
EOF
    
    log_success "Directory structure created successfully"
}

# Update system and install essential packages
update_system() {
    show_progress "Updating system and installing essential packages..."
    
    log_info "Updating package lists..."
    sudo apt update
    
    log_info "Upgrading existing packages..."
    sudo apt upgrade -y
    
    # Install essential packages
    local essential_packages=(
        "curl"
        "wget"
        "git"
        "vim"
        "nano"
        "htop"
        "tree"
        "unzip"
        "zip"
        "p7zip-full"
        "build-essential"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "python3"
        "python3-pip"
        "python3-venv"
        "python3-dev"
        "default-jdk"
        "nodejs"
        "npm"
        "golang-go"
        "jq"
        "yq"
        "tmux"
        "screen"
        "net-tools"
        "nmap"
        "masscan"
        "nikto"
        "dirb"
        "gobuster"
        "ffuf"
        "sqlmap"
        "john"
        "hashcat"
        "hydra"
        "medusa"
        "metasploit-framework"
        "burpsuite"
        "wireshark"
        "tcpdump"
        "aircrack-ng"
        "recon-ng"
        "theharvester"
        "maltego"
        "spiderfoot"
        "certbot"
        "python3-certbot-apache"
        "tldr"
        "spice-vdagent"
    )
    
    log_info "Installing essential packages..."
    for package in "${essential_packages[@]}"; do
        if sudo apt install -y "$package"; then
            log_info "✓ Installed: $package"
        else
            log_warn "✗ Failed to install: $package"
        fi
    done
    
    log_success "System update and essential packages installation completed"
}

# Install Docker and container tools (using shared functions)
install_docker_kali() {
    show_progress "Installing Docker and container tools..."
    
    # Source shared functions if not already loaded
    if ! command -v install_docker &> /dev/null; then
        source "$SCRIPT_DIR/../shared/install-functions.sh" 2>/dev/null || {
            log_warn "Shared functions not available, using local Docker installation"
            install_docker_local
            return $?
        }
    fi
    
    # Use shared Docker installation function
    install_docker
}

# Local Docker installation fallback
install_docker_local() {
    # Remove old Docker versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package list and install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Install docker-compose (standalone)
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    log_success "Docker installation completed"
    log_info "Note: You may need to log out and back in for Docker group membership to take effect"
}

# Install development environments
install_development_tools() {
    show_progress "Installing development environments..."
    
    # Install Rust
    log_info "Installing Rust programming language..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    
    # Add Windows target for Rust (useful for cross-compilation)
    rustup target add x86_64-pc-windows-gnu
    sudo apt install -y gcc-mingw-w64-x86-64
    
    # Install additional Python tools
    log_info "Installing Python development tools..."
    pip3 install --user --upgrade pip
    pip3 install --user virtualenv pipenv poetry
    pip3 install --user requests beautifulsoup4 scrapy
    pip3 install --user pwntools ropper
    pip3 install --user impacket
    
    # Install Node.js tools
    log_info "Installing Node.js development tools..."
    sudo npm install -g yarn
    sudo npm install -g @angular/cli
    sudo npm install -g create-react-app
    sudo npm install -g electron
    
    # Install Go tools
    log_info "Installing Go development tools..."
    go install github.com/OJ/gobuster/v3@latest
    go install github.com/ffuf/ffuf@latest
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    
    log_success "Development environments installed"
}

# Clone essential security repositories
clone_security_repositories() {
    show_progress "Cloning essential security repositories..."
    
    cd "$HOME/security/github"
    
    # Define repositories to clone
    local repositories=(
        "https://github.com/swisskyrepo/PayloadsAllTheThings.git"
        "https://github.com/1N3/IntruderPayloads.git"
        "https://github.com/fuzzdb-project/fuzzdb.git"
        "https://github.com/The-Art-of-Hacking/h4cker.git"
        "https://github.com/OlivierLaflamme/Cheatsheet-God.git"
        "https://github.com/danielmiessler/SecLists.git"
        "https://github.com/almandin/fuxploider.git"
        "https://github.com/EmpireProject/Empire.git"
        "https://github.com/BloodHoundAD/BloodHound.git"
        "https://github.com/SecureAuthCorp/impacket.git"
        "https://github.com/samratashok/nishang.git"
        "https://github.com/Tib3rius/AutoRecon.git"
        "https://github.com/fin3ss3g0d/evilgophish.git"
        "https://github.com/mttaggart/rustyneedle.git"
        "https://github.com/carlospolop/PEASS-ng.git"
        "https://github.com/rebootuser/LinEnum.git"
        "https://github.com/PowerShellMafia/PowerSploit.git"
        "https://github.com/bitsadmin/wesng.git"
        "https://github.com/AonCyberLabs/Windows-Exploit-Suggester.git"
        "https://github.com/rasta-mouse/Sherlock.git"
    )
    
    # Clone repositories with error handling
    for repo in "${repositories[@]}"; do
        repo_name=$(basename "$repo" .git)
        if [[ -d "$repo_name" ]]; then
            log_info "Repository $repo_name already exists, updating..."
            cd "$repo_name"
            git pull
            cd ..
        else
            log_info "Cloning $repo_name..."
            if git clone "$repo"; then
                log_info "✓ Successfully cloned $repo_name"
            else
                log_warn "✗ Failed to clone $repo_name"
            fi
        fi
    done
    
    # Organize repositories
    log_info "Organizing cloned repositories..."
    
    # Create symbolic links with shorter names
    [[ -d "PayloadsAllTheThings" ]] && ln -sf PayloadsAllTheThings patt
    [[ -d "IntruderPayloads" ]] && ln -sf IntruderPayloads intrude
    [[ -d "SecLists" ]] && ln -sf SecLists seclists
    
    # Move wordlists to appropriate directory
    if [[ -d "fuzzdb" ]]; then
        cp -r fuzzdb/* "$HOME/security/recon/wordlists/" 2>/dev/null || true
    fi
    
    if [[ -d "IntruderPayloads" ]]; then
        cp -r IntruderPayloads/* "$HOME/security/recon/wordlists/" 2>/dev/null || true
    fi
    
    if [[ -d "PayloadsAllTheThings" ]]; then
        cp -r PayloadsAllTheThings/* "$HOME/security/recon/wordlists/" 2>/dev/null || true
    fi
    
    if [[ -d "SecLists" ]]; then
        cp -r SecLists/* "$HOME/security/recon/wordlists/" 2>/dev/null || true
    fi
    
    # Move specific tools to appropriate directories
    [[ -d "fuxploider" ]] && mv fuxploider "$HOME/security/recon/"
    [[ -d "impacket" ]] && mv impacket "$HOME/security/recon/"
    [[ -d "nishang" ]] && mv nishang "$HOME/security/post/win/"
    [[ -d "AutoRecon" ]] && mv AutoRecon "$HOME/security/recon/"
    [[ -d "rustyneedle" ]] && mv rustyneedle "$HOME/security/payloads/"
    
    # Install Python requirements for impacket
    if [[ -d "$HOME/security/recon/impacket" ]]; then
        log_info "Installing impacket requirements..."
        cd "$HOME/security/recon/impacket"
        pip3 install --user -r requirements.txt
        python3 setup.py install --user
        cd "$HOME/security/github"
    fi
    
    log_success "Security repositories cloned and organized"
}

# Install additional applications
install_applications() {
    show_progress "Installing additional applications..."
    
    # Install Google Chrome
    log_info "Installing Google Chrome..."
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
    sudo apt update
    sudo apt install -y google-chrome-stable
    
    # Install Visual Studio Code
    log_info "Installing Visual Studio Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt update
    sudo apt install -y code
    
    # Install Sublime Text
    log_info "Installing Sublime Text..."
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    sudo apt update
    sudo apt install -y sublime-text
    
    # Install additional security tools
    log_info "Installing additional security tools..."
    
    # Install Bloodhound
    sudo apt install -y bloodhound
    
    # Install CrackMapExec
    pip3 install --user crackmapexec
    
    # Install Responder
    sudo apt install -y responder
    
    # Install enum4linux-ng
    pip3 install --user enum4linux-ng
    
    # Install kerbrute
    go install github.com/ropnop/kerbrute@latest
    
    log_success "Additional applications installed"
}

# Configure system and create useful aliases
configure_system() {
    show_progress "Configuring system and creating useful aliases..."
    
    # Create useful aliases
    log_info "Creating useful aliases..."
    
    # Backup existing bashrc
    cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add custom aliases to bashrc
    cat >> "$HOME/.bashrc" << 'EOF'

# ============================================
# Custom Security Testing Aliases
# ============================================

# Directory shortcuts
alias sec='cd ~/security'
alias github='cd ~/security/github'
alias recon='cd ~/security/recon'
alias targets='cd ~/security/targets'
alias payloads='cd ~/security/payloads'
alias engaged='cd ~/security/engaged'

# Quick directory creation
alias smd='sudo mkdir -p'
alias mkd='mkdir -p'

# Enhanced ls commands
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lh='ls -lah'

# Network and system information
alias myip='curl -s ifconfig.me'
alias localip='ip route get 1 | awk "{print \$NF;exit}"'
alias ports='netstat -tulanp'
alias listening='netstat -tlnp'
alias connections='netstat -anp'

# Security tool shortcuts
alias nmap-quick='nmap -T4 -F'
alias nmap-full='nmap -T4 -A -v'
alias nmap-udp='nmap -sU -T4'
alias gobuster-dir='gobuster dir -w ~/security/recon/wordlists/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt'
alias gobuster-dns='gobuster dns -w ~/security/recon/wordlists/SecLists/Discovery/DNS/subdomains-top1million-5000.txt'

# Python shortcuts
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Docker shortcuts
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dc='docker-compose'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'

# System monitoring
alias cpu='top -o %CPU'
alias mem='top -o %MEM'
alias disk='df -h'
alias temp='sensors'

# Quick file operations
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# History
alias h='history'
alias hg='history | grep'

# Process management
alias psg='ps aux | grep'
alias killall='killall -v'

# Archive operations
alias tar-create='tar -czf'
alias tar-extract='tar -xzf'
alias tar-list='tar -tzf'

# Security testing functions
function scan-host() {
    if [ -z "$1" ]; then
        echo "Usage: scan-host <target>"
        return 1
    fi
    echo "Scanning $1..."
    nmap -T4 -A -v "$1"
}

function enum-web() {
    if [ -z "$1" ]; then
        echo "Usage: enum-web <target-url>"
        return 1
    fi
    echo "Enumerating web directories for $1..."
    gobuster dir -u "$1" -w ~/security/recon/wordlists/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt
}

function check-ssl() {
    if [ -z "$1" ]; then
        echo "Usage: check-ssl <domain>"
        return 1
    fi
    echo "Checking SSL certificate for $1..."
    echo | openssl s_client -servername "$1" -connect "$1:443" 2>/dev/null | openssl x509 -noout -dates
}

# Update PATH for Go binaries
export PATH=$PATH:~/go/bin

# Update PATH for Rust binaries
export PATH=$PATH:~/.cargo/bin

# Update PATH for local Python binaries
export PATH=$PATH:~/.local/bin

EOF
    
    # Create a security testing profile
    cat > "$HOME/.security_profile" << 'EOF'
#!/bin/bash
# Security Testing Environment Profile

# Set environment variables for security testing
export SECURITY_HOME="$HOME/security"
export WORDLISTS="$HOME/security/recon/wordlists"
export PAYLOADS="$HOME/security/payloads"
export TARGETS="$HOME/security/targets"

# Function to start a new engagement
function new-engagement() {
    if [ -z "$1" ]; then
        echo "Usage: new-engagement <target-name>"
        return 1
    fi
    
    local target_dir="$TARGETS/$1"
    mkdir -p "$target_dir"/{recon,enum,exploit,post,screenshots,notes}
    
    echo "Created engagement directory structure for: $1"
    echo "Directory: $target_dir"
    cd "$target_dir"
}

# Function to create a quick note
function note() {
    local note_file="$HOME/security/engaged/notes/$(date +%Y%m%d_%H%M%S)_note.md"
    echo "# Quick Note - $(date)" > "$note_file"
    echo "" >> "$note_file"
    echo "$*" >> "$note_file"
    echo "Note saved to: $note_file"
}

# Function to backup current engagement
function backup-engagement() {
    local backup_dir="$HOME/security/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r "$HOME/security/engaged"/* "$backup_dir/"
    echo "Engagement backed up to: $backup_dir"
}

echo "Security testing environment loaded!"
echo "Use 'new-engagement <target>' to start a new engagement"
EOF
    
    # Source the security profile in bashrc
    echo "source ~/.security_profile" >> "$HOME/.bashrc"
    
    # Configure Git (if not already configured)
    if ! git config --global user.name >/dev/null 2>&1; then
        log_info "Configuring Git..."
        read -p "Enter your Git username: " git_username
        read -p "Enter your Git email: " git_email
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
    fi
    
    # Configure tmux
    log_info "Configuring tmux..."
    cat > "$HOME/.tmux.conf" << 'EOF'
# Tmux configuration for security testing

# Set prefix to Ctrl-a
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Enable mouse support
set -g mouse on

# Set default terminal
set -g default-terminal "screen-256color"

# Start windows and panes at 1
set -g base-index 1
setw -g pane-base-index 1

# Reload config file
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Status bar
set -g status-bg black
set -g status-fg white
set -g status-left '#[fg=green]#H '
set -g status-right '#[fg=yellow]%Y-%m-%d %H:%M'
EOF
    
    log_success "System configuration completed"
}

# Final setup and cleanup
final_setup() {
    show_progress "Performing final setup and cleanup..."
    
    # Update locate database
    log_info "Updating locate database..."
    sudo updatedb
    
    # Clean up package cache
    log_info "Cleaning up package cache..."
    sudo apt autoremove -y
    sudo apt autoclean
    
    # Set proper permissions
    log_info "Setting proper permissions..."
    chmod -R 755 "$HOME/security"
    chmod 600 "$HOME/.security_profile"
    
    # Create desktop shortcuts
    log_info "Creating desktop shortcuts..."
    mkdir -p "$HOME/Desktop"
    
    # Security directory shortcut
    cat > "$HOME/Desktop/Security.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Link
Name=Security Directory
Comment=Quick access to security testing directory
URL=file://$HOME/security
Icon=folder
EOF
    
    chmod +x "$HOME/Desktop/Security.desktop"
    
    # Create a summary report
    log_info "Creating setup summary..."
    cat > "$HOME/security/SETUP_SUMMARY.md" << EOF
# Kali Linux Setup Summary

Setup completed on: $(date)

## Installed Components

### System Updates
- System packages updated to latest versions
- Essential development tools installed

### Development Environments
- Python 3 with pip, virtualenv, pipenv, poetry
- Rust with Windows cross-compilation support
- Go with essential security tools
- Node.js with npm and yarn
- Java Development Kit

### Security Tools
- Network scanning: nmap, masscan
- Web testing: gobuster, ffuf, nikto, dirb
- Password attacks: john, hashcat, hydra, medusa
- Framework tools: metasploit, burpsuite
- Network analysis: wireshark, tcpdump
- Wireless: aircrack-ng
- OSINT: recon-ng, theharvester, maltego, spiderfoot

### Containerization
- Docker CE with docker-compose
- User added to docker group

### Applications
- Google Chrome
- Visual Studio Code
- Sublime Text

### Security Repositories
- PayloadsAllTheThings
- SecLists
- Impacket
- Nishang
- AutoRecon
- And many more...

## Directory Structure
- ~/security/ - Main security testing directory
- ~/security/github/ - Cloned repositories
- ~/security/recon/ - Reconnaissance tools and wordlists
- ~/security/targets/ - Target-specific materials
- ~/security/payloads/ - Exploit payloads
- ~/security/engaged/ - Active engagement materials

## Custom Aliases and Functions
- Directory shortcuts (sec, github, recon, etc.)
- Security tool shortcuts (nmap-quick, gobuster-dir, etc.)
- Engagement management functions (new-engagement, note, backup-engagement)

## Next Steps
1. Log out and back in to apply group memberships
2. Source the new bashrc: source ~/.bashrc
3. Test Docker: docker run hello-world
4. Start a new engagement: new-engagement <target-name>
5. Explore the security directory structure

## Security Reminders
- Always obtain proper authorization before testing
- Use tools responsibly and ethically
- Keep tools and wordlists updated
- Document all testing activities
- Follow responsible disclosure practices

Happy hacking! (Ethically, of course)
EOF
    
    log_success "Final setup completed"
}

# Main execution function
main() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              Fresh Kali Linux Setup Script                  ║
║                                                              ║
║    Comprehensive setup for security testing environment     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    log_info "Starting Fresh Kali Linux setup..."
    log_warn "This script will install numerous packages and tools."
    log_warn "Ensure you have a stable internet connection and sufficient disk space."
    
    # Confirmation prompt
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled by user."
        exit 0
    fi
    
    # Execute setup steps
    check_root
    check_requirements
    create_directory_structure
    update_system
    install_docker_kali
    install_development_tools
    clone_security_repositories
    install_applications
    configure_system
    final_setup
    
    # Success message
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                    SETUP COMPLETED!                         ║
║                                                              ║
║   Your Kali Linux system is now ready for security testing  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    log_success "Fresh Kali Linux setup completed successfully!"
    echo
    log_info "Summary of what was installed:"
    log_info "• Organized directory structure in ~/security/"
    log_info "• Essential security tools and frameworks"
    log_info "• Development environments (Python, Rust, Go, Node.js)"
    log_info "• Docker and containerization tools"
    log_info "• Popular security repositories and wordlists"
    log_info "• Custom aliases and shortcuts"
    log_info "• GUI applications (Chrome, VS Code, Sublime Text)"
    echo
    log_warn "IMPORTANT NEXT STEPS:"
    log_warn "1. Log out and back in to apply group memberships"
    log_warn "2. Run 'source ~/.bashrc' to load new aliases"
    log_warn "3. Test Docker with 'docker run hello-world'"
    log_warn "4. Review ~/security/SETUP_SUMMARY.md for details"
    echo
    log_info "Use 'new-engagement <target-name>' to start a new security assessment"
    log_info "All tools should only be used with proper authorization!"
    echo
    log_success "Happy ethical hacking! 🔒"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
