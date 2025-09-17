#!/bin/bash
# Ensure root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

# Define the URL and filename
URL="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-9.1.3-amd64.deb"
FILE="superdupermalware_amd64.deb"

# Download the file
wget "$URL" -O "$FILE"

# Install the package
sudo dpkg -i "$FILE"
