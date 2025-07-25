#!/bin/bash

wait_for_dpkg_lock() {
  local max_attempts=30
  local attempt=0
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    pid=$(fuser /var/lib/dpkg/lock-frontend 2>/dev/null)
    echo "Waiting for dpkg lock to be released (held by PID $pid)..."
    attempt=$((attempt+1))
    if [ "$attempt" -ge "$max_attempts" ]; then
      echo "Lock held too long. Killing PID $pid..."
      kill -9 "$pid"
      break
    fi
    sleep 2
  done
}


# Get the IP address of kubernetes-vm
IP=$(getent hosts kubernetes-vm | awk '{ print $1 }')

# Check if IP was found
if [[ -z "$IP" ]]; then
  echo "Could not resolve kubernetes-vm"
  exit 1
fi

# Backup current hosts file
sudo cp /etc/hosts /etc/hosts.bak

# Indent existing lines by 3 spaces and write back
sudo sed 's/^/   /' /etc/hosts.bak > /tmp/hosts.tmp

# Add the new mappings
{
  echo "$IP fleet-server-agent-http.default.svc"
  echo "$IP elasticsearch-es-http.default.svc"
} >> /tmp/hosts.tmp

# Replace the original file
sudo mv /tmp/hosts.tmp /etc/hosts

echo "Updated /etc/hosts with indentation and aliases:"
echo " - fleet-server-agent-http.default.svc -> $IP"
echo " - elasticsearch-es-http.default.svc -> $IP"
