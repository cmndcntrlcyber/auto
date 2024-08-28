#!/bin/bash

# Variables
DISK="/dev/sdb"
PARTITION="${DISK}1"
MOUNT_POINT="/mnt/mydisk"
FILESYSTEM="ext4"

# Unmount the partition if it's already mounted
echo "Unmounting ${PARTITION} if mounted..."
sudo umount ${PARTITION} 2>/dev/null

# Create a new partition (optional, comment this out if not needed)
echo "Creating a new partition on ${DISK}..."
echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk ${DISK}

# Format the partition with the desired filesystem
echo "Formatting ${PARTITION} with ${FILESYSTEM} filesystem..."
sudo mkfs.${FILESYSTEM} ${PARTITION}

# Create the mount point directory
echo "Creating mount point at ${MOUNT_POINT}..."
sudo mkdir -p ${MOUNT_POINT}

# Mount the partition to the mount point
echo "Mounting ${PARTITION} to ${MOUNT_POINT}..."
sudo mount ${PARTITION} ${MOUNT_POINT}

# Add to /etc/fstab for automatic mounting (optional)
echo "Would you like to add this to /etc/fstab for automatic mounting at boot? (y/n)"
read -r ADD_TO_FSTAB

if [ "$ADD_TO_FSTAB" == "y" ]; then
    echo "Adding ${PARTITION} to /etc/fstab..."
    echo "${PARTITION}  ${MOUNT_POINT}  ${FILESYSTEM}  defaults  0  2" | sudo tee -a /etc/fstab
fi

# Verify the mount
echo "Verifying the mount..."
df -h | grep ${PARTITION}

echo "Done!"
