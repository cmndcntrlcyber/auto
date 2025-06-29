# Tools - Specialized Security & Analysis Tools

This directory contains specialized tools for security testing, analysis, and system administration. These tools are designed for authorized security professionals and system administrators.

## ⚠️ Security Warning

**All tools in this directory are for authorized security testing and educational purposes only.**

- Obtain proper written authorization before using these tools
- Ensure compliance with applicable laws and regulations
- Use responsibly in controlled environments
- The authors are not responsible for misuse

## 📁 Directory Contents

### 🐍 Python Tools (`py/`)

- **`ntlm_spray_pass.py`** - Advanced NTLM password spraying tool
- **`migrate-connect.py`** - Database migration utilities
- **`preprocess_pdfs.py`** - PDF processing and data extraction
- **`test-migrate.py`** - Database migration testing

## 🛠️ Tool Documentation

### ntlm_spray_pass.py

**Purpose**: Secure NTLM password spraying tool for testing authentication endpoints with proper rate limiting and security controls.

**Features**:
- Thread-safe password spraying with rate limiting
- Comprehensive logging and result tracking
- Multiple authentication attempt modes
- Built-in security safeguards to prevent account lockouts
- Detailed reporting and analysis
- Command-line interface with extensive options

**Usage**:
```bash
# Single password spray
python3 ntlm_spray_pass.py \
  --domain example.com \
  --users userlist.txt \
  --password "Password123" \
  --target https://target.example.com/ \
  --delay 2 \
  --verbose

# Multiple password spray
python3 ntlm_spray_pass.py \
  --domain example.com \
  --users userlist.txt \
  --passwords passwords.txt \
  --target https://target.example.com/ \
  --threads 3 \
  --delay 1.5

# With custom output
python3 ntlm_spray_pass.py \
  --domain example.com \
  --users userlist.txt \
  --password "Summer2024!" \
  --target https://mail.example.com/owa/ \
  --output results.txt \
  --verbose
```

**Command-Line Options**:
```
Required Arguments:
  -d, --domain DOMAIN     Fully Qualified Domain Name (FQDN)
  -u, --users FILE        Username list file (one per line)
  -t, --target URL        Target URL for authentication

Password Options (choose one):
  -p, --password PASS     Single password to test
  -P, --passwords FILE    Password list file (one per line)

Optional Arguments:
  --delay SECONDS         Delay between attempts (default: 1.0)
  --threads NUM           Maximum threads (default: 5)
  --timeout SECONDS       Request timeout (default: 30)
  -v, --verbose           Enable verbose output
  -o, --output FILE       Output file for results
```

**Security Features**:
- **Rate Limiting**: Configurable delays between attempts
- **Thread Control**: Limited concurrent connections
- **Account Lockout Prevention**: Built-in safeguards
- **Comprehensive Logging**: Detailed audit trail
- **Input Validation**: Sanitized inputs and URL validation
- **Authorization Check**: Interactive authorization prompt

**Example Output**:
```
NTLM Password Spray Tool - Authorized Security Testing Only

⚠️  SECURITY WARNING
This tool is for authorized security testing only.
Ensure you have proper authorization before proceeding.

Do you have authorization to test the target? (yes/no): yes

Starting password spray attack using password: Password123
Target URL: https://mail.example.com/owa/
Testing 50 users

✓ Valid credential found - jsmith:Password123
✓ Valid credential found - mwilson:Password123

Password spray completed:
  Valid credentials found: 2
  Failed attempts: 48
  Errors: 0

FINAL RESULTS
Valid credentials found: 2
Failed attempts: 48
Errors: 0

Successful Credentials:
  jsmith:Password123
  mwilson:Password123

Detailed results saved to: ntlm_spray_results.txt
```

### migrate-connect.py

**Purpose**: Database migration utilities for managing database schema changes and data transfers.

**Features**:
- Multiple database backend support
- Schema migration tracking
- Rollback capabilities
- Data validation and integrity checks

**Usage**:
```bash
# Run database migrations
python3 migrate-connect.py --migrate --config db_config.json

# Rollback last migration
python3 migrate-connect.py --rollback --config db_config.json

# Check migration status
python3 migrate-connect.py --status --config db_config.json
```

### preprocess_pdfs.py

**Purpose**: PDF processing and data extraction tool for security analysis and document processing.

**Features**:
- Text extraction from PDF documents
- Metadata analysis
- Batch processing capabilities
- Security-focused content analysis

**Usage**:
```bash
# Process single PDF
python3 preprocess_pdfs.py --input document.pdf --output extracted_text.txt

# Batch process directory
python3 preprocess_pdfs.py --batch /path/to/pdfs/ --output-dir /path/to/output/

# Extract metadata
python3 preprocess_pdfs.py --input document.pdf --metadata --output metadata.json
```

## 🚀 Installation & Setup

### Prerequisites

```bash
# Install Python dependencies
pip install -r ../requirements.txt

# Additional dependencies for specific tools
pip install requests-ntlm  # For NTLM authentication
pip install PyPDF2 pdfplumber  # For PDF processing
pip install sqlalchemy psycopg2-binary  # For database tools
```

### System Dependencies

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y python3-dev libpq-dev

# CentOS/RHEL
sudo yum install -y python3-devel postgresql-devel

# macOS
brew install postgresql
```

## 🔒 Security Best Practices

### Before Using These Tools

1. **Authorization**: Obtain written authorization from system owners
2. **Scope Definition**: Clearly define testing scope and limitations
3. **Legal Review**: Ensure compliance with applicable laws
4. **Documentation**: Document all testing activities
5. **Notification**: Inform relevant stakeholders

### During Testing

1. **Rate Limiting**: Use appropriate delays to prevent service disruption
2. **Monitoring**: Monitor system resources and performance
3. **Logging**: Maintain comprehensive logs of all activities
4. **Escalation**: Have incident response procedures ready
5. **Communication**: Maintain communication with system owners

### After Testing

1. **Cleanup**: Remove any test artifacts or accounts
2. **Reporting**: Provide detailed findings and recommendations
3. **Data Handling**: Securely handle and dispose of sensitive data
4. **Follow-up**: Assist with remediation efforts as needed

## 📋 Configuration Examples

### NTLM Spray Configuration

**Username List (users.txt)**:
```
jsmith
mwilson
bthompson
agarcia
rjohnson
```

**Password List (passwords.txt)**:
```
Password123
Summer2024!
Company123
Welcome2024
Password!
```

**Target URLs**:
- Exchange OWA: `https://mail.domain.com/owa/`
- SharePoint: `https://sharepoint.domain.com/`
- IIS Applications: `https://app.domain.com/secure/`

### Database Migration Configuration

**db_config.json**:
```json
{
  "database": {
    "type": "postgresql",
    "host": "localhost",
    "port": 5432,
    "database": "myapp",
    "username": "dbuser",
    "password": "secure_password"
  },
  "migrations": {
    "directory": "./migrations",
    "table": "schema_migrations"
  },
  "backup": {
    "enabled": true,
    "directory": "./backups"
  }
}
```

## 🐛 Troubleshooting

### Common Issues

1. **NTLM Authentication Failures**
   ```bash
   # Check target URL accessibility
   curl -I https://target.domain.com/
   
   # Verify domain format
   # Use FQDN: domain.com (not DOMAIN or domain)
   
   # Test single credential manually
   python3 -c "
   import requests
   from requests_ntlm import HttpNtlmAuth
   r = requests.get('https://target.com/', auth=HttpNtlmAuth('DOMAIN\\user', 'pass'))
   print(r.status_code)
   "
   ```

2. **Database Connection Issues**
   ```bash
   # Test database connectivity
   python3 -c "
   import psycopg2
   conn = psycopg2.connect(host='localhost', database='test', user='user', password='pass')
   print('Connection successful')
   conn.close()
   "
   ```

3. **PDF Processing Errors**
   ```bash
   # Check PDF file integrity
   python3 -c "
   import PyPDF2
   with open('document.pdf', 'rb') as f:
       reader = PyPDF2.PdfReader(f)
       print(f'Pages: {len(reader.pages)}')
   "
   ```

### Error Messages

- **"Invalid URL format"**: Ensure URL includes protocol (https://)
- **"Domain not in allowed list"**: Check domain whitelist configuration
- **"Connection timeout"**: Increase timeout value or check network connectivity
- **"Authentication failed"**: Verify credentials and domain format

## 📊 Output Formats

### NTLM Spray Results

**Console Output**:
```
✓ Valid credential found - username:password
✗ Failed login - username:password
⚠ Unexpected response for username - Status: 403
```

**Results File (ntlm_spray_results.txt)**:
```
NTLM Password Spray Results
==================================================

Successful Credentials (2):
------------------------------
jsmith:Password123
mwilson:Password123

Failed Attempts (48):
--------------------
agarcia:Password123 (Status: 401)
bthompson:Password123 (Status: 401)
...

Errors (0):
----------
```

### Migration Status Output

```json
{
  "current_version": "20240101_001",
  "pending_migrations": [
    "20240102_001_add_user_table",
    "20240103_001_add_indexes"
  ],
  "last_migration": "2024-01-01T10:30:00Z",
  "status": "up_to_date"
}
```

## 🔄 Maintenance

### Regular Tasks

1. **Update Dependencies**:
   ```bash
   pip install --upgrade -r ../requirements.txt
   ```

2. **Security Updates**:
   ```bash
   # Check for security vulnerabilities
   pip install safety
   safety check
   ```

3. **Log Rotation**:
   ```bash
   # Rotate large log files
   find . -name "*.log" -size +100M -exec gzip {} \;
   ```

### Performance Optimization

1. **NTLM Spray Tuning**:
   - Adjust thread count based on target capacity
   - Optimize delay settings for speed vs. stealth
   - Monitor memory usage with large user lists

2. **Database Operations**:
   - Use connection pooling for multiple operations
   - Implement batch processing for large datasets
   - Monitor transaction log growth

## 🤝 Contributing

### Adding New Tools

1. **Follow naming conventions**: Use descriptive, lowercase names with underscores
2. **Include comprehensive documentation**: Add docstrings and comments
3. **Implement security features**: Input validation, rate limiting, logging
4. **Add command-line interface**: Use argparse for consistency
5. **Include examples**: Provide usage examples and test cases

### Code Standards

```python
"""
Tool Name - Brief Description

Detailed description of the tool's purpose and functionality.

SECURITY WARNING: Include appropriate security warnings.

Author: Security Automation Team
Version: X.Y.Z
License: MIT
"""

import argparse
import logging
import sys
from typing import List, Dict, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    """Main function with argument parsing and error handling"""
    parser = argparse.ArgumentParser(description="Tool description")
    # Add arguments
    
    try:
        args = parser.parse_args()
        # Tool logic here
        
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

---

**Remember**: These tools are powerful and should be used responsibly. Always ensure you have proper authorization and follow ethical guidelines when conducting security testing.
