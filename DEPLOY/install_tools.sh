#!/bin/bash

# install_tools.sh
# Installs necessary tools for deployment: Terraform, AWS CLI, Google Cloud SDK
# Supports macOS (Homebrew) and Linux (apt/yum)

set -e

echo "Checking for required tools..."

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    *)          machine="UNKNOWN:${OS}"
esac

echo "Detected OS: $machine"

# Install Terraform
if command_exists terraform; then
  echo "Terraform is already installed."
else
  echo "Installing Terraform..."
  if [ "$machine" == "Mac" ]; then
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
  elif [ "$machine" == "Linux" ]; then
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt-get install terraform
  fi
fi

# Install AWS CLI
if command_exists aws; then
  echo "AWS CLI is already installed."
else
  echo "Installing AWS CLI..."
  if [ "$machine" == "Mac" ]; then
    brew install awscli
  elif [ "$machine" == "Linux" ]; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
  fi
fi

# Install Google Cloud SDK
if command_exists gcloud; then
  echo "Google Cloud SDK is already installed."
else
  echo "Installing Google Cloud SDK..."
  if [ "$machine" == "Mac" ]; then
    brew install --cask google-cloud-sdk
  elif [ "$machine" == "Linux" ]; then
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    sudo apt-get update && sudo apt-get install google-cloud-cli
  fi
fi

echo "All tools checked/installed."
echo "Please ensure you run 'aws configure' and 'gcloud init' to set up your credentials."
