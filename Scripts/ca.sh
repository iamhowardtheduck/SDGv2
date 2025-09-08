#!/bin/bash

# Variables
SRC_CERT="/etc/ssl/certs/nginx-selfsined.crt"
DEST_CERT="/usr/local/share/ca-certificates/ca.crt"
DEST_HOST1="host-1"

# HOST 1

echo "Copying $SRC_CERT to $DEST_HOST1:$DEST_CERT ..."
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SRC_CERT" "$DEST_HOST1:/tmp/ca.crt"
if [ $? -ne 0 ]; then
    echo "SCP failed! Exiting."
    exit 1
fi

echo "Moving cert to $DEST_CERT and updating CA store on $DEST_HOST ..."
ssh -o StrictHostKeyChecking=accept-new "$DEST_HOST1" "sudo mv /tmp/ca.crt $DEST_CERT && sudo update-ca-certificates"

if [ $? -eq 0 ]; then
    echo "Certificate installed and CA store updated on $DEST_HOST1."
else
    echo "Failed to update CA store on $DEST_HOST1."
    exit 2
fi
