# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Security automation toolkit — a collection of Bash and Python scripts for penetration testing, infrastructure provisioning, and security operations. **All tools are for authorized security testing only.**

## Setup

```bash
pip install -r requirements.txt
find . -name "*.sh" -type f -exec chmod +x {} \;
```

Most shell scripts require `sudo` and target Ubuntu/Debian (apt-based). Fresh install scripts (`fresh/`) are meant to be run on newly provisioned systems.

## Architecture

Scripts are organized by purpose into these directories:

| Directory | Purpose | Language |
|-----------|---------|----------|
| `builders/` | Infrastructure deployment (CI/CD, Flask, LLM, Docker) | Bash |
| `configs/` | Docker compose templates, Dockerfiles, web/Windows configs | YAML/PS1 |
| `connectors/` | Database and VPN connection utilities | Python/Bash |
| `engagers/` | Security testing tools (nmap, MITRE ATT&CK, ransim) | Python |
| `fresh/` | Fresh OS setup scripts (Kali, Ubuntu, BTPI, RTPI) | Bash |
| `functions/` | Reusable pipes (e.g., threat emulator pipeline) | Python |
| `generators/` | Data/credential generators (passwords, corp users) | Python |
| `maintainers/` | System maintenance (certs, mounts, AD join, Ollama) | Bash/Python |
| `modifiers/` | System modification (XRDP, HTTPS, Flask deploy, AD) | Mixed |
| `preppers/` | Data preparation (Flask web prep, LLM PDF preprocessing) | Python |
| `tools/py/` | Specialized tools (NTLM spray, DB migration, PDF processing, web-to-markdown) | Python |
| `shared/` | `install-functions.sh` — shared library for logging, package management, Docker install, error handling | Bash |

## Key Patterns

- **Shared functions library**: Shell scripts should `source shared/install-functions.sh` for consistent logging (`log_info`, `log_error`, `log_step`, `log_success`), package installation with retry logic, Docker setup, and error handling.
- **BTPI/RTPI naming**: Blue Team Platform Init / Red Team Platform Init — these are environment archetypes with matching fresh scripts, Docker compose templates, and Dockerfiles.
- **Snippets**: `builders/snippets/py/` contains reusable Python classes (`SecureExecutionEnvironment`, `WebAgent`) used by other scripts.
- **Docker compose templates**: Located in `configs/docker/compose templates/` (note the space in the directory name). Named as `{purpose}.docker-compose.yml`.

## Running Tools

```bash
# Fresh system setup (requires sudo)
sudo ./fresh/fresh-kali.sh

# Password generation
python3 generators/pass-gen.py -l 16 --verbose

# Network scanning
python3 engagers/nmap-init.py

# Web content extraction
python3 tools/py/web-to-markdown.py https://example.com output.md

# Flask deployment
bash modifiers/flask-app-deployer.sh

# NTLM password spray (authorized testing only)
python3 tools/py/ntlm_spray_pass.py --domain example.com --users userlist.txt --password "Pass" --target https://target/
```

## Notes

- No test suite or linter is configured for this repo — scripts are standalone utilities.
- Python scripts expect Python 3.8+.
- The `LLM/` directory exists but is currently empty.
- `configs/docker/compose templates/` has a space in the path — always quote it in shell commands.
