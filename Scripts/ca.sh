#!/bin/bash

# Run setup-GDI.sh first
bash SDGv2/Scripts/setup-GDI.sh

# Variables
#SRC_CERT="/etc/ssl/certs/nginx-selfsined.crt"
#DEST_CERT="/usr/local/share/ca-certificates/ca.crt"
#DEST_HOST1="host-1"

# HOST 1

echo "Copying $SRC_CERT to $DEST_HOST1:$DEST_CERT ..."
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /etc/ssl/certs/nginx-selfsigned.crt host-1:/tmp/ca.crt
if [ $? -ne 0 ]; then
    echo "SCP failed! Exiting."
    exit 1
fi

echo "Moving cert to $DEST_CERT and updating CA store on $DEST_HOST ..."
ssh -o StrictHostKeyChecking=accept-new "host-1" "sudo mv /tmp/ca.crt /usr/local/share/ca-certificates/ca.crt && sudo update-ca-certificates"

if [ $? -eq 0 ]; then
    echo "Certificate installed and CA store updated on $DEST_HOST1."
else
    echo "Failed to update CA store on $DEST_HOST1."
    exit 2
fi
