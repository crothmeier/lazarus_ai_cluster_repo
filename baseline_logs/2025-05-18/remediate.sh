#!/bin/bash
# Remediation script for phx-hypervisor26
# Generated: 2025-05-18

set -e

echo "=== Starting system remediation ==="

# 1. Fix networkd-wait-online timeout
echo "=== Fixing networkd-wait-online timeout ==="
sudo mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d/
cat << 'EOF' | sudo tee /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf
[Service]
ExecStart=
ExecStart=/lib/systemd/systemd-networkd-wait-online --timeout=30
EOF
sudo systemctl daemon-reload

# 2. Fix ZFS export errors
echo "=== Fixing ZFS export errors ==="
# Create exports directory and fix permissions
sudo mkdir -p /etc/exports.d
sudo touch /etc/exports.d/zfs.exports
sudo chown root:root /etc/exports.d/zfs.exports
sudo chmod 644 /etc/exports.d/zfs.exports

# Disable ZFS sharing services if no NFS shares are needed
# sudo systemctl disable zfs-share
# sudo systemctl stop zfs-share

# 3. Configure passwordless sudo for specific commands
echo "=== Configuring passwordless sudo ==="
cat << 'EOF' | sudo tee /etc/sudoers.d/99-cluster-baseline
# Allow passwordless sudo for specific commands
crathmene ALL=(root) NOPASSWD: /usr/sbin/hpasmcli, /usr/sbin/dmidecode
EOF
sudo chmod 440 /etc/sudoers.d/99-cluster-baseline

# 4. Check k3s installation
echo "=== Checking k3s installation ==="
if ! command -v k3s >/dev/null 2>&1; then
  echo "K3s not installed; skipping cluster checks"
  # Uncomment below to install k3s if needed
  # curl -sfL https://get.k3s.io | sh -
else
  echo "K3s is installed, enabling service"
  sudo systemctl enable --now k3s
fi

# 5. Validate Restic restore capability
echo "=== Validating Restic backup restore ==="
if ! command -v restic >/dev/null 2>&1; then
  echo "Restic not installed; skipping backup validation"
else
  if [ -z "$RESTIC_REPO" ]; then
    echo "⚠️ RESTIC_REPO environment variable not set"
    echo "Please set RESTIC_REPO to run restic commands, example:"
    echo "export RESTIC_REPO=s3:https://s3.example.com/restic-repo"
  else
    echo "Attempting test restore from latest snapshot"
    mkdir -p ~/restic_test
    # Uncomment and adjust to test restore a specific small file
    # restic -r $RESTIC_REPO restore latest --target ~/restic_test --include /path/to/small/file.txt
    echo "See comments in script to enable actual test restore"
  fi
fi

# 6. Check firmware and driver versions
echo "=== Checking firmware and driver versions ==="
if command -v dmidecode >/dev/null 2>&1; then
  BIOS_VERSION=$(sudo dmidecode -s bios-version)
  echo "Current BIOS version: $BIOS_VERSION"
  echo "Check HPE support site for latest BIOS version and update if needed"
else
  echo "⚠️ dmidecode not installed, cannot check BIOS version"
fi

if command -v nvidia-smi >/dev/null 2>&1; then
  NVIDIA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
  echo "Current NVIDIA driver version: $NVIDIA_VERSION"
  echo "Latest NVIDIA drivers in 555-series should be checked on nvidia.com"
  if [[ "$NVIDIA_VERSION" != 555* ]]; then
    echo "⚠️ NVIDIA driver not on 555-series, consider updating"
  fi
else
  echo "NVIDIA tools not installed or no NVIDIA GPU detected"
fi

# 7. Setup monitoring integration
echo "=== Setting up monitoring integration ==="
if [ -f "/etc/prometheus/prometheus.yml" ]; then
  echo "Prometheus configuration found, adding node configuration"
  # Make a backup of the original config
  sudo cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.bak.$(date +%F)
  
  # Copy the config from our prepared file
  sudo cp ~/baseline_logs/$(date +%F)/prometheus-config.yml /tmp/
  echo "Adding the following to Prometheus configuration:"
  cat ~/baseline_logs/$(date +%F)/prometheus-config.yml
  
  # Append our config to prometheus.yml
  echo "# Added by system remediation on $(date +%F)" | sudo tee -a /etc/prometheus/prometheus.yml
  cat ~/baseline_logs/$(date +%F)/prometheus-config.yml | sudo tee -a /etc/prometheus/prometheus.yml
  
  # Reload Prometheus if it's running
  if systemctl is-active --quiet prometheus; then
    sudo systemctl reload prometheus
    echo "Prometheus configuration reloaded"
  else
    echo "Prometheus service not running, configuration updated but not reloaded"
  fi
else
  echo "Prometheus configuration not found at /etc/prometheus/prometheus.yml"
  echo "Example node exporter configuration saved to ~/baseline_logs/$(date +%F)/prometheus-config.yml"
fi

# 8. Setup recurring baseline schedule
echo "=== Setting up recurring baseline schedule ==="
# Copy service and timer files
sudo cp ~/baseline_logs/$(date +%F)/baseline.service /etc/systemd/system/
sudo cp ~/baseline_logs/$(date +%F)/baseline.timer /etc/systemd/system/

# Update the paths in the service file to point to the script
sudo sed -i "s|/home/crathmene/baseline_logs/\$(date +%F)/remediate.sh|/home/crathmene/baseline_logs/remediate.sh|g" /etc/systemd/system/baseline.service

# Create a permanent copy of the remediation script
sudo cp ~/baseline_logs/$(date +%F)/remediate.sh /home/crathmene/baseline_logs/remediate.sh
sudo chmod +x /home/crathmene/baseline_logs/remediate.sh

# Enable and start the timer
sudo systemctl daemon-reload
sudo systemctl enable baseline.timer
sudo systemctl start baseline.timer
echo "Baseline timer enabled and started"