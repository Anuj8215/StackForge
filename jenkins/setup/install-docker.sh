#!/bin/bash
# install-docker.sh — Run on the same EC2 as Jenkins
set -euo pipefail

echo "=== [1/5] Installing prerequisites ==="
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg

echo "=== [2/5] Adding Docker GPG key ==="
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "=== [3/5] Adding Docker repository ==="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== [4/5] Installing Docker Engine ==="
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== [5/5] Adding jenkins user to docker group ==="
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

echo ""
echo "Docker installed successfully"
docker --version
