#!/bin/bash
# install-jenkins.sh — Run on a fresh Ubuntu EC2 t2.medium
set -euo pipefail

echo "=== [1/4] Installing Java 17 ==="
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jdk

echo "=== [2/4] Adding Jenkins repository ==="
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "=== [3/4] Installing Jenkins ==="
sudo apt-get update -y
sudo apt-get install -y jenkins

echo "=== [4/4] Starting Jenkins ==="
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo ""
echo "Jenkins is running on port 8080"
echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
