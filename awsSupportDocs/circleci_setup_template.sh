#!/bin/bash

# Exit immediately if any command fails
set -e

# Update package lists and install Docker dependencies
sudo apt-get update
sudo apt-get upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu || true
sudo usermod -aG docker $USER || true

# Start configuration of self-hosted machine
# Download the launch agent binary and verify the checksum
mkdir -p configurations
cd configurations
curl https://raw.githubusercontent.com/CircleCI-Public/runner-installation-files/main/download-launch-agent.sh > download-launch-agent.sh
export platform=linux/amd64 && sh ./download-launch-agent.sh
cd ..

# Create the circleci user & working directory
id -u circleci &>/dev/null || sudo adduser --disabled-password --gecos GECOS circleci
sudo mkdir -p /var/opt/circleci
sudo chmod 0750 /var/opt/circleci
sudo chown -R circleci /var/opt/circleci /opt/circleci/circleci-launch-agent

# Create a CircleCI runner configuration file programmatically
sudo mkdir -p /etc/opt/circleci
cat << 'EOF' | sudo tee /etc/opt/circleci/launch-agent-config.yaml > /dev/null
api:
  auth_token: 17f70d59d059a9c24d6e37d51afb969f8ccf10124be54033a0a2b0f8a645a7e187ec1551d3d07042

runner:
  name: self-hosted
  working_directory: /var/opt/circleci/workdir
  cleanup_working_directory: true
EOF

sudo chown circleci: /etc/opt/circleci/launch-agent-config.yaml
sudo chmod 600 /etc/opt/circleci/launch-agent-config.yaml

# Create the Systemd service file programmatically
cat << 'EOF' | sudo tee /usr/lib/systemd/system/circleci.service > /dev/null
[Unit]
Description=CircleCI Runner
After=network.target

[Service]
ExecStart=/opt/circleci/circleci-launch-agent --config /etc/opt/circleci/launch-agent-config.yaml
Restart=always
User=circleci
NotifyAccess=exec
TimeoutStopSec=18300

[Install]
WantedBy=multi-user.target
EOF

sudo chown root: /usr/lib/systemd/system/circleci.service
sudo chmod 644 /usr/lib/systemd/system/circleci.service

# Start and Enable CircleCI Service
sudo systemctl daemon-reload
sudo systemctl enable circleci.service
sudo systemctl start circleci.service

# Add circleci user to docker group so the runner can start containers
sudo usermod -aG docker circleci
sudo systemctl restart circleci.service

# Print status of the service
sudo systemctl status circleci.service --no-pager

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install -y unzip
unzip -o awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws/

echo "Setup completed successfully!"

# NOTE: Make sure to add the following variables inside your CircleCI Project Settings:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_REGION (ap-south-1)
# - AWS_ECR_REGISTRY_ID (844099234694)