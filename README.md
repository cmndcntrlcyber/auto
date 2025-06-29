# Security Automation Toolkit

A comprehensive collection of cybersecurity automation tools, scripts, and configurations for penetration testing, infrastructure management, and security operations.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Bash](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)

## ⚠️ Security Warning

**This toolkit is designed for authorized security testing and educational purposes only.**

- Ensure you have proper written authorization before using these tools
- Unauthorized access to computer systems is illegal
- Use responsibly and in compliance with applicable laws and regulations
- The authors are not responsible for misuse of these tools

## 📋 Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Tool Categories](#tool-categories)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)

## 🔍 Overview

This repository contains a curated collection of security automation tools organized into logical categories:

- **Build Automation**: CI/CD and infrastructure deployment scripts
- **Configuration Management**: Docker, web server, and system configurations
- **Network Tools**: Connection utilities and network automation
- **Security Testing**: Penetration testing and vulnerability assessment tools
- **System Administration**: Fresh installations, maintenance, and modification scripts
- **Data Processing**: Generators, preprocessors, and analysis tools

## 📁 Directory Structure

```
├── builders/           # Build automation and CI/CD scripts
│   ├── snippets/      # Reusable code snippets and classes
│   └── *.sh          # Build and deployment scripts
├── configs/           # Configuration files and templates
│   ├── docker/       # Docker configurations and compose files
│   ├── web/          # Web server configurations
│   └── windows/      # Windows-specific configurations
├── connectors/        # Database and network connection utilities
├── engagers/          # Security testing and engagement tools
├── fresh/            # Fresh system installation scripts
├── functions/        # Utility functions and pipes
├── generators/       # Data and credential generators
├── maintainers/      # System maintenance scripts
├── modifiers/        # System modification tools
├── preppers/         # Data preparation and preprocessing tools
├── random/           # Miscellaneous utilities
└── tools/            # Specialized security and analysis tools
```

## 🚀 Installation

### Prerequisites

- **Python 3.8+** with pip
- **Bash shell** (Linux/macOS/WSL)
- **Docker** (for containerized tools)
- **Git** for repository management

### Basic Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd security-automation-toolkit
   ```

2. **Install Python dependencies:**
   ```bash
   # Create virtual environment (recommended)
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   
   # Install common dependencies
   pip install -r requirements.txt
   ```

3. **Make scripts executable:**
   ```bash
   find . -name "*.sh" -type f -exec chmod +x {} \;
   ```

4. **Install system dependencies** (Ubuntu/Debian):
   ```bash
   sudo apt update
   sudo apt install -y curl wget git docker.io docker-compose
   ```

### Tool-Specific Setup

Some tools require additional setup. See individual tool documentation for details.

## 🏃 Quick Start

### 1. Password Generation
```bash
# Generate a secure password
python3 generators/pass-gen.py
```

### 2. System Information
```bash
# Get system information using SecureExecutionEnvironment
python3 -c "
from builders.snippets.py.class-SecureExecutionEnvironment import SecureExecutionEnvironment
executor = SecureExecutionEnvironment(['uname', '-a'])
executor.start()
executor.wait_for_completion()
print(executor.get_output()['stdout'])
"
```

### 3. Fresh Kali Setup
```bash
# Set up a fresh Kali Linux environment
sudo ./fresh/fresh-kali.sh
```

### 4. Docker Environment
```bash
# Build a custom Docker environment
./builders/build-automation.sh
```

## 🛠️ Tool Categories

### 🏗️ Builders
Automation scripts for building and deploying infrastructure:

- **`build-automation.sh`**: Gitea and Drone CI installation with SSL
- **`build-flask.sh`**: Flask application deployment
- **`build-llm.sh`**: Large Language Model setup
- **`snippets/`**: Reusable Python classes and utilities

### ⚙️ Configs
Configuration files and templates:

- **Docker**: Compose files for various services (BloodHound, CTI, etc.)
- **Web**: Server configurations and attack frameworks
- **Windows**: PowerShell scripts for AD, taskbar, wallpaper management

### 🔗 Connectors
Network and database connection utilities:

- **`connect-db.py`**: Database connection management
- **`openconnect.sh`**: VPN connection automation

### 🎯 Engagers
Security testing and engagement tools:

- **`attck.py`**: MITRE ATT&CK TTP execution framework
- **`nmap-init.py`**: Network scanning automation
- **`ransim.py`**: Ransomware simulation for testing

### 🆕 Fresh
Fresh system installation and setup scripts:

- **`fresh-kali.sh`**: Complete Kali Linux setup with tools
- **`fresh-btpi.sh`**: Blue Team Platform initialization
- **`fresh-rtpi.sh`**: Red Team Platform initialization

### 🔧 Tools
Specialized security and analysis tools:

- **`ntlm_spray_pass.py`**: NTLM password spraying tool
- **`migrate-connect.py`**: Database migration utilities
- **`preprocess_pdfs.py`**: PDF processing for data extraction

## 🔒 Security Considerations

### Best Practices

1. **Authorization**: Always obtain written authorization before testing
2. **Isolation**: Use isolated environments for testing
3. **Logging**: Enable comprehensive logging for all activities
4. **Rate Limiting**: Implement delays to prevent service disruption
5. **Cleanup**: Remove test artifacts after completion

### Tool-Specific Security

- **Password Tools**: Use secure random generation
- **Network Tools**: Implement connection timeouts and error handling
- **Execution Tools**: Validate inputs and sanitize commands
- **Docker Tools**: Use non-root users and security contexts

### Compliance

Ensure compliance with:
- Local and international laws
- Organizational policies
- Industry regulations (GDPR, HIPAA, etc.)
- Ethical hacking guidelines

## 📚 Documentation

### Individual Tool Documentation

Each tool includes comprehensive documentation:

- **Purpose and functionality**
- **Installation requirements**
- **Usage examples**
- **Security considerations**
- **Troubleshooting guides**

### Configuration Examples

```bash
# Example: NTLM Password Spray
python3 tools/py/ntlm_spray_pass.py \
  --domain example.com \
  --users userlist.txt \
  --password "Password123" \
  --target https://target.example.com/ \
  --delay 2 \
  --verbose

# Example: Secure Command Execution
python3 -c "
from builders.snippets.py.class-SecureExecutionEnvironment import SecureExecutionEnvironment
executor = SecureExecutionEnvironment(['ls', '-la'], timeout=10)
executor.start()
if executor.wait_for_completion(timeout=15):
    result = executor.get_output()
    print(f'Status: {executor.get_status()}')
    print(f'Output: {result[\"stdout\"]}')
"
```

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Follow coding standards
4. Add comprehensive documentation
5. Include security considerations
6. Test thoroughly

### Code Standards

- **Python**: Follow PEP 8, use type hints, include docstrings
- **Bash**: Use proper error handling, quote variables, check exit codes
- **Documentation**: Include purpose, parameters, examples, and security notes
- **Security**: Validate inputs, handle errors, log activities

### Pull Request Process

1. Update documentation
2. Add/update tests
3. Ensure security review
4. Update CHANGELOG.md
5. Request review from maintainers

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help

- **Documentation**: Check individual tool documentation
- **Issues**: Create GitHub issues for bugs or feature requests
- **Security**: Report security issues privately to maintainers

### Common Issues

1. **Permission Denied**: Ensure scripts are executable (`chmod +x`)
2. **Missing Dependencies**: Install required packages and Python modules
3. **Network Issues**: Check firewall settings and network connectivity
4. **Docker Issues**: Ensure Docker daemon is running and user has permissions

## 🔄 Changelog

### Version 2.1.0 (Current)
- **File Consolidation**: Removed redundant files and consolidated functionality
- **Shared Functions Library**: Created unified installation and utility functions
- **Enhanced Tools**: Upgraded basic tools with advanced features and security
- **Improved Organization**: Better file structure and logical grouping
- **Security Enhancements**: Replaced dangerous `exec()` calls with secure alternatives
- **Comprehensive Documentation**: Complete documentation for all tools and processes
- **Error Handling**: Added proper exception handling and logging throughout
- **Type Safety**: Added type hints and validation to Python code

### Version 2.0.0
- **Security Enhancements**: Replaced dangerous `exec()` calls with secure alternatives
- **Improved Documentation**: Comprehensive documentation for all tools
- **Error Handling**: Added proper exception handling and logging
- **Type Safety**: Added type hints and validation
- **Threading Support**: Fixed missing imports and improved thread safety

### Version 1.0.0
- Initial release with basic functionality
- Core tools and scripts
- Basic documentation

## 🏷️ Tags

`cybersecurity` `penetration-testing` `automation` `security-tools` `red-team` `blue-team` `docker` `python` `bash` `ntlm` `mitre-attack` `infrastructure` `ci-cd`

---

**Remember**: With great power comes great responsibility. Use these tools ethically and legally.
