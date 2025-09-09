#!/bin/bash
# MTProxy Auto Installer for Ubuntu 22.04
# Author: ChatGPT

set -e

echo "=== MTProxy Auto Installer ==="

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git curl build-essential libssl-dev zlib1g-dev

# Clone MTProxy repo
if [ ! -d "/opt/MTProxy" ]; then
    sudo git clone https://github.com/TelegramMessenger/MTProxy /opt/MTProxy
fi

cd /opt/MTProxy
sudo make

# Fetch proxy secret and config
sudo curl -s https://core.telegram.org/getProxySecret -o /opt/MTProxy/proxy-secret
sudo curl -s https://core.telegram.org/getProxyConfig -o /opt/MTProxy/proxy-multi.conf

# Generate random secret
SECRET=$(head -c 16 /dev/urandom | xxd -ps)
echo "Your generated secret: $SECRET"

# Create systemd service
cat <<EOF | sudo tee /etc/systemd/system/mtproxy.service
[Unit]
Description=MTProxy Telegram Proxy
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/MTProxy
ExecStart=/opt/MTProxy/objs/bin/mtproto-proxy -u nobody -p 8888 -H 443 -S $SECRET --aes-pwd proxy-secret proxy-multi.conf -M 1
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
sudo systemctl daemon-reload
sudo systemctl enable mtproxy
sudo systemctl start mtproxy

# Show status
sudo systemctl status mtproxy --no-pager

echo
echo "=== MTProxy Installed Successfully ==="
echo "Telegram Proxy Link:"
echo "tg://proxy?server=$(curl -s ifconfig.me)&port=443&secret=$SECRET"
