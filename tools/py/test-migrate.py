import socket
import ssl
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def send_test_request(host, port, message):
    try:
        context = ssl.create_default_context()
        with socket.create_connection((host, port)) as sock:
            with context.wrap_socket(sock, server_hostname=host) as ssock:
                logging.info(f"Connected to {host}:{port}")
                ssock.sendall(message.encode('utf-8'))
                response = ssock.recv(4096)
                logging.info(f"Received response: {response.decode('utf-8')}")
    except Exception as e:
        logging.error(f"Failed to send test request: {e}")

def main():
    target_host = "bounty.attck-node.net"
    target_port = 14553
    test_message = "TEST_CONNECTION\n"

    logging.info(f"Sending test request to {target_host}:{target_port}")
    send_test_request(target_host, target_port, test_message)

if __name__ == "__main__":
    main()