#!/bin/bash

# Exit immediately if any command fails
set -e

# Update packages and install Docker dependencies
sudo apt-get update
sudo apt-get upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Add current user and ubuntu user to docker group
sudo usermod -aG docker ubuntu || true
sudo usermod -aG docker $USER || true

# Install CircleCI Runner Repository and Package (Machine Runner 3.0)
curl -s https://packagecloud.io/install/repositories/circleci/runner/script.deb.sh?any=true | sudo bash
sudo apt-get update
sudo apt-get install -y circleci-runner

# Create the configuration file for the runner agent
sudo mkdir -p /etc/circleci-runner
cat << 'EOF' | sudo tee /etc/circleci-runner/circleci-runner-config.yaml > /dev/null
api:
  auth_token: "2b2ca47aa216fdf4361ca74467bfd53c58b0e190262b73b28ab1a30920f942b00037571454b5fcf0"

runner:
  name: "self-hosted"
  working_directory: "/var/lib/circleci-runner/workdir"
  cleanup_working_directory: true
EOF

# Give appropriate permissions to the configuration file
sudo chmod 600 /etc/circleci-runner/circleci-runner-config.yaml

# Enable the runner service
sudo systemctl daemon-reload
sudo systemctl enable circleci-runner

# Add the circleci-runner user to the docker group so it can start docker tasks
sudo usermod -aG docker circleci-runner || true
sudo usermod -aG docker circleci || true

# Start the runner service
sudo systemctl start circleci-runner

# Print status of the runner service
sudo systemctl status circleci-runner --no-pager

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