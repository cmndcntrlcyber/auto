import secrets
import string

# Generate a strong alphanumeric password
def generate_alphanumeric_password(length=12):
    # Characters to generate password from (only alphanumeric characters)
    characters = string.ascii_letters + string.digits
    # Creating a secure password
    secure_password = ''.join(secrets.choice(characters) for i in range(length))
    return secure_password

# Generate and print a 12-character strong alphanumeric password
generate_alphanumeric_password()
print(generate_alphanumeric_password)