#!/bin/bash

# Get the IP address of interface ens4
ENS4_IP=$(ip -4 addr show ens4 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Check if IP was found
if [[ -z "$ENS4_IP" ]]; then
    echo "Error: Could not determine IP address for interface ens4."
    exit 1
fi

echo "Detected ens4 IP: $ENS4_IP"

# Run elasticsearch-certutil with the detected IP and specify the output zip file
echo "Logstash.zip" | ./bin/elasticsearch-certutil cert \
  --name Logstash \
  --ca-cert /usr/share/elasticsearch/ca/ca.crt \
  --ca-key /usr/share/elasticsearch/ca/ca.key \
  --pem \
  --dns host-1 \
  --ip "$ENS4_IP" \
  --pem
