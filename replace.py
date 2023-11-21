#!/bin/python3

import sys
import shutil
import os

# copy the applications from development in /opt/ to /var/www/apps
def copy_directory(src, dst):
    """
    Copy files from the source directory to the destination directory.
    """
    try:
        # Create the destination directory if it doesn't exist
        if not os.path.exists(dst):
            os.makedirs(dst)

        # Copy each file from src to dst
        for item in os.listdir(src):
            s = os.path.join(src, item)
            d = os.path.join(dst, item)
            if os.path.isdir(s):
                shutil.copytree(s, d, dirs_exist_ok=True)
            else:
                shutil.copy2(s, d)
        print(f"Copied files from {src} to {dst}")
    except Exception as e:
        print(f"Error occurred: {e}")

# Check the number of arguments
if len(sys.argv) != 3:
    print("[*] Usage: python update-web.py <SOURCE_DIRECTORY> <DESTINATION_DIRECTORY>")
    sys.exit(-1)

# Take 2 arguments, source directory, destination directory
src = sys.argv[1]
dst = sys.argv[2]

# Copy the applications from development in /opt/ to /var/www/apps
copy_directory(src, dst)