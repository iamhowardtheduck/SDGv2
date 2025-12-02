# !/bin/bash

# Ensure root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

#######################################
# TASK1
#######################################
(
  echo
  echo "Pre-loading malware simulation / aka security sprinkles; this may take a minute."
  echo
  cd /root
set -e  
# --- APT installs (no prompts) ---
sudo -E NEEDRESTART_MODE=a apt-get update -y
sudo -E NEEDRESTART_MODE=a apt-get install -y \
  build-essential pkg-config libssl-dev gcc-12 g++-12 \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold"

# Set gcc-12 as default
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100
sudo update-alternatives --set gcc /usr/bin/gcc-12
sudo update-alternatives --set g++ /usr/bin/g++-12

# Install Rust non-interactively
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# Install Oniux
cargo install --git https://gitlab.torproject.org/tpo/core/oniux.git --tag v0.4.0 --locked -v
sudo cp ~/.cargo/bin/oniux /usr/local/bin/
CMD=('oniux' 'curl' '-4' 'https://icanhazip.com')
COUNT=3

for ((i=1; i<=COUNT; i++)); do
  echo "[$(date --iso-8601=seconds)] Run #$i"
  "${CMD[@]}"
done

echo "[$(date --iso-8601=seconds)] All $COUNT runs completed."
) &
PID1=$!

#######################################
# TASK2
#######################################
(
  URL="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-9.1.3-amd64.deb"
  FILE="superdupermalware_amd64.deb"

  wget "$URL" -O "$FILE"
  sudo dpkg -i "$FILE"
 ) &
PID2=$!

#######################################
# Wait for both tasks
#######################################
wait $PID1
echo "TASK1 completed."

wait $PID2
echo "TASK2 completed."

echo "All tasks finished!"
