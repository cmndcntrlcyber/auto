import socket
import threading
import random
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def handle_client(client_socket, address, new_port):
    logging.info(f"Connection migrated to port {new_port} for {address}")
    try:
        with client_socket:
            while True:
                data = client_socket.recv(1024)
                if not data:
                    break
                logging.info(f"Received data from {address}: {data.decode('utf-8')}")
                # Echo the data back (for validation purposes)
                client_socket.sendall(data)
    except Exception as e:
        logging.error(f"Error handling client {address}: {e}")

def migrate_connection(client_socket, address):
    new_port = random.randint(15000, 20000)
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as new_server:
            new_server.bind(('0.0.0.0', new_port))
            new_server.listen(1)
            logging.info(f"Listening on port {new_port} for migration from {address}")
            client_socket.sendall(f"MIGRATE {new_port}\n".encode('utf-8'))
            conn, addr = new_server.accept()
            client_thread = threading.Thread(target=handle_client, args=(conn, addr, new_port))
            client_thread.start()
    except Exception as e:
        logging.error(f"Error migrating connection for {address}: {e}")

def main():
    listen_port = 14553
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
            server.bind(('0.0.0.0', listen_port))
            server.listen(5)
            logging.info(f"Listening on port {listen_port} for incoming connections...")

            while True:
                client_socket, address = server.accept()
                logging.info(f"Accepted connection from {address}")
                migration_thread = threading.Thread(target=migrate_connection, args=(client_socket, address))
                migration_thread.start()
    except Exception as e:
        logging.error(f"Server error: {e}")

if __name__ == "__main__":
    main()
