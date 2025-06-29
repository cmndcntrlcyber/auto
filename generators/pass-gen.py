"""
Secure Password Generator

A cryptographically secure password generator with customizable options
for creating strong passwords suitable for various security requirements.

Features:
- Cryptographically secure random generation using secrets module
- Customizable character sets and password policies
- Multiple output formats (single password, batch generation)
- Password strength validation
- Entropy calculation
- Command-line interface with extensive options

Author: Security Automation Team
Version: 2.0.0
License: MIT
"""

import secrets
import string
import argparse
import sys
import math
import re
from typing import List, Dict, Optional, Set
import json


class PasswordPolicy:
    """
    Password policy configuration class
    
    Defines rules and requirements for password generation including
    character requirements, length constraints, and complexity rules.
    """
    
    def __init__(self,
                 min_length: int = 12,
                 max_length: int = 128,
                 require_uppercase: bool = True,
                 require_lowercase: bool = True,
                 require_digits: bool = True,
                 require_special: bool = True,
                 min_uppercase: int = 1,
                 min_lowercase: int = 1,
                 min_digits: int = 1,
                 min_special: int = 1,
                 exclude_ambiguous: bool = False,
                 exclude_similar: bool = False,
                 custom_special_chars: Optional[str] = None):
        """
        Initialize password policy
        
        Args:
            min_length (int): Minimum password length
            max_length (int): Maximum password length
            require_uppercase (bool): Require uppercase letters
            require_lowercase (bool): Require lowercase letters
            require_digits (bool): Require digits
            require_special (bool): Require special characters
            min_uppercase (int): Minimum number of uppercase letters
            min_lowercase (int): Minimum number of lowercase letters
            min_digits (int): Minimum number of digits
            min_special (int): Minimum number of special characters
            exclude_ambiguous (bool): Exclude ambiguous characters (0, O, l, 1, etc.)
            exclude_similar (bool): Exclude similar looking characters
            custom_special_chars (str, optional): Custom special character set
        """
        self.min_length = min_length
        self.max_length = max_length
        self.require_uppercase = require_uppercase
        self.require_lowercase = require_lowercase
        self.require_digits = require_digits
        self.require_special = require_special
        self.min_uppercase = min_uppercase
        self.min_lowercase = min_lowercase
        self.min_digits = min_digits
        self.min_special = min_special
        self.exclude_ambiguous = exclude_ambiguous
        self.exclude_similar = exclude_similar
        self.custom_special_chars = custom_special_chars
        
        # Validate policy
        self._validate_policy()
    
    def _validate_policy(self):
        """Validate that the policy is internally consistent"""
        min_required = (
            (self.min_uppercase if self.require_uppercase else 0) +
            (self.min_lowercase if self.require_lowercase else 0) +
            (self.min_digits if self.require_digits else 0) +
            (self.min_special if self.require_special else 0)
        )
        
        if min_required > self.min_length:
            raise ValueError(
                f"Minimum character requirements ({min_required}) "
                f"exceed minimum length ({self.min_length})"
            )
        
        if self.min_length > self.max_length:
            raise ValueError(
                f"Minimum length ({self.min_length}) "
                f"exceeds maximum length ({self.max_length})"
            )


class SecurePasswordGenerator:
    """
    Secure password generator with advanced features
    
    This class provides cryptographically secure password generation
    with customizable policies, character sets, and validation.
    """
    
    # Character sets
    UPPERCASE = string.ascii_uppercase
    LOWERCASE = string.ascii_lowercase
    DIGITS = string.digits
    SPECIAL_CHARS = "!@#$%^&*()-_+={}[]|;':\",./<>?/~`"
    
    # Ambiguous characters that can be confused
    AMBIGUOUS_CHARS = "0O1lI|"
    SIMILAR_CHARS = "il1Lo0O"
    
    def __init__(self, policy: Optional[PasswordPolicy] = None):
        """
        Initialize the password generator
        
        Args:
            policy (PasswordPolicy, optional): Password policy to use
        """
        self.policy = policy or PasswordPolicy()
        self._build_character_sets()
    
    def _build_character_sets(self):
        """Build character sets based on policy"""
        self.uppercase_chars = self.UPPERCASE
        self.lowercase_chars = self.LOWERCASE
        self.digit_chars = self.DIGITS
        self.special_chars = (
            self.policy.custom_special_chars 
            if self.policy.custom_special_chars 
            else self.SPECIAL_CHARS
        )
        
        # Remove ambiguous characters if requested
        if self.policy.exclude_ambiguous:
            self.uppercase_chars = ''.join(
                c for c in self.uppercase_chars 
                if c not in self.AMBIGUOUS_CHARS
            )
            self.lowercase_chars = ''.join(
                c for c in self.lowercase_chars 
                if c not in self.AMBIGUOUS_CHARS
            )
            self.digit_chars = ''.join(
                c for c in self.digit_chars 
                if c not in self.AMBIGUOUS_CHARS
            )
        
        # Remove similar characters if requested
        if self.policy.exclude_similar:
            self.uppercase_chars = ''.join(
                c for c in self.uppercase_chars 
                if c not in self.SIMILAR_CHARS
            )
            self.lowercase_chars = ''.join(
                c for c in self.lowercase_chars 
                if c not in self.SIMILAR_CHARS
            )
            self.digit_chars = ''.join(
                c for c in self.digit_chars 
                if c not in self.SIMILAR_CHARS
            )
        
        # Build combined character set
        self.all_chars = ""
        if self.policy.require_uppercase:
            self.all_chars += self.uppercase_chars
        if self.policy.require_lowercase:
            self.all_chars += self.lowercase_chars
        if self.policy.require_digits:
            self.all_chars += self.digit_chars
        if self.policy.require_special:
            self.all_chars += self.special_chars
    
    def generate_password(self, length: Optional[int] = None) -> str:
        """
        Generate a single password
        
        Args:
            length (int, optional): Password length (uses policy default if not specified)
            
        Returns:
            str: Generated password
        """
        if length is None:
            length = self.policy.min_length
        
        if length < self.policy.min_length or length > self.policy.max_length:
            raise ValueError(
                f"Length {length} is outside policy range "
                f"({self.policy.min_length}-{self.policy.max_length})"
            )
        
        # Generate password with required character types
        password_chars = []
        
        # Add minimum required characters
        if self.policy.require_uppercase:
            password_chars.extend(
                secrets.choice(self.uppercase_chars) 
                for _ in range(self.policy.min_uppercase)
            )
        
        if self.policy.require_lowercase:
            password_chars.extend(
                secrets.choice(self.lowercase_chars) 
                for _ in range(self.policy.min_lowercase)
            )
        
        if self.policy.require_digits:
            password_chars.extend(
                secrets.choice(self.digit_chars) 
                for _ in range(self.policy.min_digits)
            )
        
        if self.policy.require_special:
            password_chars.extend(
                secrets.choice(self.special_chars) 
                for _ in range(self.policy.min_special)
            )
        
        # Fill remaining length with random characters from all allowed sets
        remaining_length = length - len(password_chars)
        password_chars.extend(
            secrets.choice(self.all_chars) 
            for _ in range(remaining_length)
        )
        
        # Shuffle the password characters
        for i in range(len(password_chars)):
            j = secrets.randbelow(len(password_chars))
            password_chars[i], password_chars[j] = password_chars[j], password_chars[i]
        
        password = ''.join(password_chars)
        
        # Validate the generated password
        if not self.validate_password(password):
            # Recursively generate until we get a valid password
            return self.generate_password(length)
        
        return password
    
    def generate_multiple_passwords(self, count: int, length: Optional[int] = None) -> List[str]:
        """
        Generate multiple passwords
        
        Args:
            count (int): Number of passwords to generate
            length (int, optional): Password length
            
        Returns:
            List[str]: List of generated passwords
        """
        return [self.generate_password(length) for _ in range(count)]
    
    def validate_password(self, password: str) -> bool:
        """
        Validate a password against the current policy
        
        Args:
            password (str): Password to validate
            
        Returns:
            bool: True if password meets policy requirements
        """
        if len(password) < self.policy.min_length or len(password) > self.policy.max_length:
            return False
        
        # Count character types
        uppercase_count = sum(1 for c in password if c in self.uppercase_chars)
        lowercase_count = sum(1 for c in password if c in self.lowercase_chars)
        digit_count = sum(1 for c in password if c in self.digit_chars)
        special_count = sum(1 for c in password if c in self.special_chars)
        
        # Check requirements
        if self.policy.require_uppercase and uppercase_count < self.policy.min_uppercase:
            return False
        if self.policy.require_lowercase and lowercase_count < self.policy.min_lowercase:
            return False
        if self.policy.require_digits and digit_count < self.policy.min_digits:
            return False
        if self.policy.require_special and special_count < self.policy.min_special:
            return False
        
        return True
    
    def calculate_entropy(self, password: str) -> float:
        """
        Calculate password entropy in bits
        
        Args:
            password (str): Password to analyze
            
        Returns:
            float: Entropy in bits
        """
        # Determine character set size
        charset_size = 0
        
        if any(c in self.uppercase_chars for c in password):
            charset_size += len(self.uppercase_chars)
        if any(c in self.lowercase_chars for c in password):
            charset_size += len(self.lowercase_chars)
        if any(c in self.digit_chars for c in password):
            charset_size += len(self.digit_chars)
        if any(c in self.special_chars for c in password):
            charset_size += len(self.special_chars)
        
        if charset_size == 0:
            return 0.0
        
        # Entropy = log2(charset_size^length)
        return len(password) * math.log2(charset_size)
    
    def analyze_password_strength(self, password: str) -> Dict[str, any]:
        """
        Analyze password strength and provide detailed metrics
        
        Args:
            password (str): Password to analyze
            
        Returns:
            Dict: Analysis results including entropy, strength rating, etc.
        """
        entropy = self.calculate_entropy(password)
        
        # Determine strength rating based on entropy
        if entropy < 30:
            strength = "Very Weak"
            color = "red"
        elif entropy < 50:
            strength = "Weak"
            color = "orange"
        elif entropy < 70:
            strength = "Fair"
            color = "yellow"
        elif entropy < 90:
            strength = "Good"
            color = "lightgreen"
        else:
            strength = "Excellent"
            color = "green"
        
        # Character composition analysis
        composition = {
            'uppercase': sum(1 for c in password if c in self.UPPERCASE),
            'lowercase': sum(1 for c in password if c in self.LOWERCASE),
            'digits': sum(1 for c in password if c in self.DIGITS),
            'special': sum(1 for c in password if c in self.SPECIAL_CHARS),
            'length': len(password)
        }
        
        # Common pattern detection
        patterns = []
        if re.search(r'(.)\1{2,}', password):
            patterns.append("Repeated characters")
        if re.search(r'(012|123|234|345|456|567|678|789|890)', password):
            patterns.append("Sequential digits")
        if re.search(r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)', password.lower()):
            patterns.append("Sequential letters")
        if re.search(r'(qwer|asdf|zxcv|1234|password|admin)', password.lower()):
            patterns.append("Common patterns")
        
        return {
            'password': password,
            'length': len(password),
            'entropy': round(entropy, 2),
            'strength': strength,
            'strength_color': color,
            'composition': composition,
            'patterns': patterns,
            'policy_compliant': self.validate_password(password),
            'estimated_crack_time': self._estimate_crack_time(entropy)
        }
    
    def _estimate_crack_time(self, entropy: float) -> str:
        """
        Estimate time to crack password based on entropy
        
        Args:
            entropy (float): Password entropy in bits
            
        Returns:
            str: Human-readable crack time estimate
        """
        # Assume 1 billion guesses per second (modern GPU)
        guesses_per_second = 1e9
        
        # Average case: half the keyspace needs to be searched
        average_guesses = (2 ** entropy) / 2
        
        seconds = average_guesses / guesses_per_second
        
        if seconds < 60:
            return f"{seconds:.1f} seconds"
        elif seconds < 3600:
            return f"{seconds/60:.1f} minutes"
        elif seconds < 86400:
            return f"{seconds/3600:.1f} hours"
        elif seconds < 31536000:
            return f"{seconds/86400:.1f} days"
        elif seconds < 31536000000:
            return f"{seconds/31536000:.1f} years"
        else:
            return f"{seconds/31536000:.0e} years"


def create_policy_from_args(args) -> PasswordPolicy:
    """
    Create a PasswordPolicy from command line arguments
    
    Args:
        args: Parsed command line arguments
        
    Returns:
        PasswordPolicy: Configured policy
    """
    return PasswordPolicy(
        min_length=args.min_length,
        max_length=args.max_length,
        require_uppercase=not args.no_uppercase,
        require_lowercase=not args.no_lowercase,
        require_digits=not args.no_digits,
        require_special=not args.no_special,
        min_uppercase=args.min_uppercase,
        min_lowercase=args.min_lowercase,
        min_digits=args.min_digits,
        min_special=args.min_special,
        exclude_ambiguous=args.exclude_ambiguous,
        exclude_similar=args.exclude_similar,
        custom_special_chars=args.special_chars
    )


def main():
    """
    Main function with comprehensive command-line interface
    """
    parser = argparse.ArgumentParser(
        description="Secure Password Generator with Advanced Features",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate a single 16-character password
  python pass-gen.py -l 16

  # Generate 5 passwords with custom policy
  python pass-gen.py -c 5 -l 20 --min-special 2 --exclude-ambiguous

  # Analyze password strength
  python pass-gen.py --analyze "MyPassword123!"

  # Generate passwords without special characters
  python pass-gen.py -l 12 --no-special

  # Use custom special characters
  python pass-gen.py -l 15 --special-chars "!@#$%"

  # Generate batch with JSON output
  python pass-gen.py -c 10 -l 16 --json
        """
    )
    
    # Generation options
    parser.add_argument('-l', '--length', type=int, default=12,
                       help='Password length (default: 12)')
    parser.add_argument('-c', '--count', type=int, default=1,
                       help='Number of passwords to generate (default: 1)')
    
    # Policy options
    parser.add_argument('--min-length', type=int, default=8,
                       help='Minimum password length (default: 8)')
    parser.add_argument('--max-length', type=int, default=128,
                       help='Maximum password length (default: 128)')
    
    # Character requirements
    parser.add_argument('--no-uppercase', action='store_true',
                       help='Exclude uppercase letters')
    parser.add_argument('--no-lowercase', action='store_true',
                       help='Exclude lowercase letters')
    parser.add_argument('--no-digits', action='store_true',
                       help='Exclude digits')
    parser.add_argument('--no-special', action='store_true',
                       help='Exclude special characters')
    
    # Minimum character counts
    parser.add_argument('--min-uppercase', type=int, default=1,
                       help='Minimum uppercase letters (default: 1)')
    parser.add_argument('--min-lowercase', type=int, default=1,
                       help='Minimum lowercase letters (default: 1)')
    parser.add_argument('--min-digits', type=int, default=1,
                       help='Minimum digits (default: 1)')
    parser.add_argument('--min-special', type=int, default=1,
                       help='Minimum special characters (default: 1)')
    
    # Character filtering
    parser.add_argument('--exclude-ambiguous', action='store_true',
                       help='Exclude ambiguous characters (0, O, l, 1, etc.)')
    parser.add_argument('--exclude-similar', action='store_true',
                       help='Exclude similar looking characters')
    parser.add_argument('--special-chars', type=str,
                       help='Custom special character set')
    
    # Analysis options
    parser.add_argument('--analyze', type=str,
                       help='Analyze strength of provided password')
    parser.add_argument('--validate', type=str,
                       help='Validate password against policy')
    
    # Output options
    parser.add_argument('--json', action='store_true',
                       help='Output in JSON format')
    parser.add_argument('--verbose', action='store_true',
                       help='Verbose output with analysis')
    parser.add_argument('--quiet', action='store_true',
                       help='Quiet mode - passwords only')
    
    args = parser.parse_args()
    
    try:
        # Create policy from arguments
        policy = create_policy_from_args(args)
        generator = SecurePasswordGenerator(policy)
        
        # Handle analysis mode
        if args.analyze:
            analysis = generator.analyze_password_strength(args.analyze)
            
            if args.json:
                print(json.dumps(analysis, indent=2))
            else:
                print(f"\nPassword Analysis for: {args.analyze}")
                print("=" * 50)
                print(f"Length: {analysis['length']}")
                print(f"Entropy: {analysis['entropy']} bits")
                print(f"Strength: {analysis['strength']}")
                print(f"Policy Compliant: {analysis['policy_compliant']}")
                print(f"Estimated Crack Time: {analysis['estimated_crack_time']}")
                
                print(f"\nCharacter Composition:")
                comp = analysis['composition']
                print(f"  Uppercase: {comp['uppercase']}")
                print(f"  Lowercase: {comp['lowercase']}")
                print(f"  Digits: {comp['digits']}")
                print(f"  Special: {comp['special']}")
                
                if analysis['patterns']:
                    print(f"\nWeak Patterns Detected:")
                    for pattern in analysis['patterns']:
                        print(f"  - {pattern}")
            
            return
        
        # Handle validation mode
        if args.validate:
            is_valid = generator.validate_password(args.validate)
            if args.json:
                print(json.dumps({"password": args.validate, "valid": is_valid}))
            else:
                status = "VALID" if is_valid else "INVALID"
                print(f"Password '{args.validate}' is {status}")
            return
        
        # Generate passwords
        if args.count == 1:
            password = generator.generate_password(args.length)
            
            if args.json:
                result = {"password": password}
                if args.verbose:
                    result.update(generator.analyze_password_strength(password))
                print(json.dumps(result, indent=2))
            elif args.quiet:
                print(password)
            else:
                print(f"Generated Password: {password}")
                
                if args.verbose:
                    analysis = generator.analyze_password_strength(password)
                    print(f"Length: {analysis['length']}")
                    print(f"Entropy: {analysis['entropy']} bits")
                    print(f"Strength: {analysis['strength']}")
                    print(f"Estimated Crack Time: {analysis['estimated_crack_time']}")
        
        else:
            passwords = generator.generate_multiple_passwords(args.count, args.length)
            
            if args.json:
                results = []
                for password in passwords:
                    result = {"password": password}
                    if args.verbose:
                        result.update(generator.analyze_password_strength(password))
                    results.append(result)
                print(json.dumps(results, indent=2))
            elif args.quiet:
                for password in passwords:
                    print(password)
            else:
                print(f"Generated {args.count} passwords:")
                for i, password in enumerate(passwords, 1):
                    print(f"{i:2d}. {password}")
                    
                    if args.verbose:
                        analysis = generator.analyze_password_strength(password)
                        print(f"    Entropy: {analysis['entropy']} bits, "
                              f"Strength: {analysis['strength']}")
    
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.", file=sys.stderr)
        sys.exit(0)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
