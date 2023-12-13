#need to troubleshoot

import requests
from bs4 import BeautifulSoup
import sys

# Check if enough arguments are provided
if len(sys.argv) < 3:
    print("Usage: python script.py [filename] [url]")
    sys.exit(1)

# Assign arguments to variables
filename = sys.argv[1]
url = sys.argv[2]

# Send a GET request to the website
response = requests.get(url)
response.raise_for_status()  # Raises an HTTPError for bad requests

# Parse the content with BeautifulSoup
soup = BeautifulSoup(response.content, 'html.parser')

# Find all <code> and <img> tags
code_tags = soup.find_all('code')
img_tags = soup.find_all('img')

# Write to the specified Markdown file
with open(filename, "w") as file:
    file.write("# Code Tags\n")
    for tag in code_tags:
        file.write(f"```\n{tag.get_text()}\n```\n\n")

    file.write("# Image Tags\n")
    for tag in img_tags:
        file.write(f"![Image]({tag['src']})\n\n")
