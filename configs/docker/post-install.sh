#!/bin/bash

# Define the users file
USERS_FILE="users.txt"

# Ensure the docker group exists
sudo groupadd docker

# Loop through each user in the users.txt file
while IFS= read -r user; do
    # Check if user exists in the system
    if id "$user" &>/dev/null; then
        echo "Processing user: $user"

        # Grant sudo access without password for 'sudo su'
        echo "$user ALL=(ALL) NOPASSWD: /bin/su" | sudo tee /etc/sudoers.d/$user

        # Add user to the docker group
        sudo usermod -aG docker "$user"

        # Ensure proper permissions for Docker usage
        sudo chown "$user":"$user" /home/"$user"/.docker -R 2>/dev/null
        sudo chmod g+rwx "$HOME/.docker" -R 2>/dev/null

    else
        echo "User $user does not exist. Skipping..."
    fi
done < "$USERS_FILE"

# Refresh group membership
newgrp docker

echo "Configuration complete."
