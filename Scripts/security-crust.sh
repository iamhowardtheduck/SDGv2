#!/bin/bash
set -e

# --- Non-interactive & auto-restart for services ---
export DEBIAN_FRONTEND=noninteractive
sudo mkdir -p /etc/needrestart/conf.d
sudo tee /etc/needrestart/conf.d/auto-restart.conf >/dev/null <<'EOF'
$nrconf{restart} = 'a';
$nrconf{kernelhints} = 0;
$nrconf{warn_on_apt_retry} = 0;
EOF

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

# Run Oniux
bash /workspace/workshop/SDGv2/Scripts/security-filling.sh
