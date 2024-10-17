import secrets
import string

# Characters to generate password from (only alphanumeric characters)
characters  = string.ascii_letters + string.digits + "!@#$%^&*()-_+={}[]|;':\",.<>?/~`"

def generate_password(length):
    """Generate a strong password with at least one special character."""
    # Create a secure password by randomly selecting characters from the provided set
    secure_password = ''.join(secrets.choice(characters) for _ in range(length))
    return secure_password

# Generate and print a 12-character strong alphanumeric password with at least one special character
print(generate_password(12))  # e.g., "!r$%@9*Qp&"