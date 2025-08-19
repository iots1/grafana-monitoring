#!/bin/bash

# Script to install Prometheus Node Exporter
# This script must be run with root privileges (e.g., using sudo)

# --- Configuration ---
# ตรวจสอบเวอร์ชันล่าสุดได้ที่: https://prometheus.io/download/#node_exporter
VERSION="1.8.1"
ARCH="amd64"

# --- Stop on error ---
set -e

# --- Check for root privileges ---
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use sudo." 
   exit 1
fi

echo "--- Step 1: Downloading Node Exporter v${VERSION} ---"
cd /tmp
wget "https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${ARCH}.tar.gz"

echo "--- Step 2: Extracting files ---"
tar xvfz "node_exporter-${VERSION}.linux-${ARCH}.tar.gz"

echo "--- Step 3: Installing Node Exporter binary ---"
mv "node_exporter-${VERSION}.linux-${ARCH}/node_exporter" /usr/local/bin/

echo "--- Step 4: Creating a dedicated user for Node Exporter ---"
# ใช้ --system เพื่อสร้าง user ที่ไม่มี home directory และไม่สามารถ login ได้
useradd --system --no-create-home --shell /bin/false node_exporter || echo "User 'node_exporter' already exists, skipping creation."

echo "--- Step 5: Creating systemd service file ---"
cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

echo "--- Step 6: Reloading systemd, enabling and starting the service ---"
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

echo "--- Step 7: Cleaning up temporary files ---"
rm -rf "/tmp/node_exporter-${VERSION}.linux-${ARCH}"
rm -f "/tmp/node_exporter-${VERSION}.linux-${ARCH}.tar.gz"

echo "--- Installation Complete! ---"
echo "Node Exporter is now active and running."
echo "You can check its status with: sudo systemctl status node_exporter"
echo "Metrics are available at: http://<your_server_ip>:9100/metrics"
