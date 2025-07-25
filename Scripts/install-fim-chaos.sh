#!/bin/bash

set -e

# Install paths
SCRIPT_PATH="/usr/local/bin/fim-chaos.sh"
SERVICE_PATH="/etc/systemd/system/fim-chaos.service"

# Create the chaos generator script
cat << 'EOF' > "$SCRIPT_PATH"
#!/bin/bash

NUM_FILES=5              # How many files to create in each loop
MAX_DEPTH=5              # Max folder depth
SLEEP_INTERVAL=10        # How long to wait between each cycle (in seconds)
MAX_FILE_LIFETIME=120    # Max file lifetime before deletion (in seconds)

# Generate random folder path under /etc
generate_random_path() {
    path="/etc"
    depth=$((RANDOM % MAX_DEPTH))
    for ((i=0; i<depth; i++)); do
        folder="folder_$(tr -dc a-z0-9 </dev/urandom | head -c 5)"
        path="$path/$folder"
    done
    echo "$path"
}

while true; do
    for ((i=1; i<=NUM_FILES; i++)); do
        dir=$(generate_random_path)
        mkdir -p "$dir"

        filename="file_$(tr -dc a-z0-9 </dev/urandom | head -c 8).conf"
        filepath="$dir/$filename"

        echo "# Random file created at $(date)" > "$filepath"

        # Random delete in background
        lifetime=$((RANDOM % MAX_FILE_LIFETIME + 1))
        (sleep "$lifetime"; rm -f "$filepath") &
    done

    sleep "$SLEEP_INTERVAL"
done
EOF

# Make the script executable
chmod +x "$SCRIPT_PATH"

# Create the systemd service unit
cat << EOF > "$SERVICE_PATH"
[Unit]
Description=FIM Chaos Generator
After=network.target

[Service]
ExecStart=$SCRIPT_PATH
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable fim-chaos
systemctl start fim-chaos

echo "FIM Chaos Generator service installed and started successfully."
