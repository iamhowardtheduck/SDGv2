#!/bin/bash
# Ensure root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

# Kick off Elastic Rule Loading
echo "Loading Elastic Rules"
curl -X POST "http://localhost:30001/api/detection_engine/rules" -u "elastic:changeme" -H "kbn-xsrf: true" -H "Content-Type: application/json" --data '{"name":"DPKG Package Installed by Unusual Parent Process","tags":["Domain: Endpoint","OS: Linux","Use Case: Threat Detection","Tactic: Persistence","Data Source: Elastic Defend","Resources: Investigation Guide"],"interval":"1m","enabled":true,"revision":1,"description":"Detects dpkg installs launched by an unusual parent process.","risk_score":21,"severity":"low","license":"Elastic License v2","output_index":"","timestamp_override":"event.ingested","author":["Elastic"],"false_positives":[],"from":"now-9m","rule_id":"101-1","max_signals":100,"risk_score_mapping":[],"severity_mapping":[],"threat":[{"framework":"MITRE ATT&CK","tactic":{"id":"TA0003","name":"Persistence","reference":"https://attack.mitre.org/tactics/TA0003/"},"technique":[{"id":"T1543","name":"Create or Modify System Process","reference":"https://attack.mitre.org/techniques/T1543/"},{"id":"T1546","name":"Event Triggered Execution","reference":"https://attack.mitre.org/techniques/T1546/","subtechnique":[{"id":"T1546.016","name":"Installer Packages","reference":"https://attack.mitre.org/techniques/T1546/016/"}]},{"id":"T1574","name":"Hijack Execution Flow","reference":"https://attack.mitre.org/techniques/T1574/"}]},{"framework":"MITRE ATT&CK","tactic":{"id":"TA0001","name":"Initial Access","reference":"https://attack.mitre.org/tactics/TA0001/"},"technique":[{"id":"T1195","name":"Supply Chain Compromise","reference":"https://attack.mitre.org/techniques/T1195/","subtechnique":[{"id":"T1195.002","name":"Compromise Software Supply Chain","reference":"https://attack.mitre.org/techniques/T1195/002/"}]}]}],"to":"now","references":["https://www.makeuseof.com/how-deb-packages-are-backdoored-how-to-detect-it/"],"version":3,"exceptions_list":[],"related_integrations":[{"package":"endpoint","version":"^8.2.0"}],"required_fields":[{"name":"event.action","type":"keyword","ecs":true},{"name":"event.category","type":"keyword","ecs":true},{"name":"event.type","type":"keyword","ecs":true},{"name":"host.os.type","type":"keyword","ecs":true},{"name":"process.args","type":"keyword","ecs":true},{"name":"process.name","type":"keyword","ecs":true}],"type":"new_terms","query":"host.os.type:linux and event.category:process and event.type:start and event.action:exec and process.name:dpkg and process.args:(\"-i\" or \"--install\")","new_terms_fields":["process.parent.executable"],"history_window_start":"now-7d","index":["logs-endpoint.events.*"],"language":"kuery","actions":[]}'
clear
echo
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
echo
echo "Security sprinkles applied, Bon Appétit!!!"
echo 
echo
