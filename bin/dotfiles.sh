#!/bin/bash

set -e

# Paths
CONFIG_DIR="$HOME/.config/dotfiles"
DOTFILES_DIR="$HOME/.dotfiles"
SSH_DIR="$HOME/.ssh"
VALUES_FILE="$HOME/.config/dotfiles/values.yml"
REPO_URL="https://github.com/lvindotexe/sysconfig-2.git"

# The extra_args variable will be set based on the current non-root user
extra_args=""

# Check if the script is running as root and warn the user
if [ "$(id -u)" -eq 0 ]; then
    echo "Warning: It's not recommended to run this script as root."
    exit 1
fi

# Check for the existence of values.yml in the current directory

if ! [[ -f "$VALUES_FILE" ]]; then
  echo "The file $VALUES_FILE does not exist. Please generate it."
  
  read -p "Would you like to generate $VALUES_FILE now? (y/n) " answer
  if [[ "$answer" = "y" ]]; then
    echo "Generating $VALUES_FILE..."
    mkdir -p "$HOME/.config/dotfiles"
    # Ask the user for their Git username and email
    read -p "Enter your Git user name: " git_user_name
    read -p "Enter your Git user email: " git_user_email

    # Generate values.yml with the user's input
    echo "---" > "$VALUES_FILE"  # Start of the YAML file
    echo "git_user_name: $git_user_name" >> "$VALUES_FILE"
    echo "git_user_email: $git_user_email" >> "$VALUES_FILE"

    echo "$VALUES_FILE generated with your Git user name and email."
  else
    echo "Please generate $VALUES_FILE before proceeding."
    exit 1
  fi
fi


# Function to install Ansible based on the detected package manager
install_ansible() {
    case "$1" in
        apt)
            sudo apt update
            sudo apt install -y software-properties-common
            sudo add-apt-repository --yes --update ppa:ansible/ansible
            sudo apt install -y ansible
            ;;
        pacman)
            sudo pacman -Sy --noconfirm ansible
            ;;
        *)
            echo "Unsupported package manager. Please install Ansible manually."
            exit 1
            ;;
    esac
}

# Function to update or clone the repository
update_or_clone_repo() {
    if [ -d "$DOTFILES_DIR" ]; then
        echo "Repository folder exists. Checking for updates..."
        cd "$DOTFILES_DIR"
        git fetch
        if git status | grep -q "Your branch is behind"; then
            echo "Repository is behind. Pulling changes..."
            git pull
        else
            echo "Repository is up to date."
        fi
    else
        echo "Cloning the repository..."
        git clone "$REPO_URL" "$DOTFILES_DIR" || { echo "Failed to clone repository."; exit 1; }
        cd "$DOTFILES_DIR"
    fi
}

# Update or clone the repository
update_or_clone_repo

# Check for Ansible and install if not present
if ! command -v ansible >/dev/null 2>&1; then
    echo "Ansible is not installed. Attempting to install Ansible..."

    # Detect package manager and install Ansible
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian)
                install_ansible "apt"
                ;;
            arch|manjaro)
                install_ansible "pacman"
                ;;
            *)
                echo "Unsupported distribution. Please manually install Ansible and rerun the script."
                exit 1
                ;;
        esac
    else
        echo "Unable to identify the operating system."
        exit 1
    fi
else
    echo "Ansible is already installed."
fi

# Generate SSH keys
# Check if SSH directory exists and has the necessary files
if [[ -f "$SSH_DIR/id_rsa" ]] && [[ -f "$SSH_DIR/id_rsa.pub" ]]; then
  echo "Existing SSH keys found. Using them."

  # Ensure the SSH directory permissions are correct
  chmod 700 "$SSH_DIR"

  # Append the public key to authorized_keys if it's not already there
  if ! grep -qF "$(cat "$SSH_DIR/id_rsa.pub")" "$SSH_DIR/authorized_keys" 2>/dev/null; then
    cat "$SSH_DIR/id_rsa.pub" >> "$SSH_DIR/authorized_keys"
    echo "Public key added to authorized_keys."
  else
    echo "Public key already in authorized_keys."
  fi
else
  # If the keys don't exist, create the directory, generate the keys, and add to authorized_keys
  echo "No existing SSH keys found. Generating new keys."
  
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  ssh-keygen -b 4096 -t rsa -f "$SSH_DIR/id_rsa" -N "" -C "$USER@$HOSTNAME"
  
  cat "$SSH_DIR/id_rsa.pub" >> "$SSH_DIR/authorized_keys"
  echo "New SSH keys generated and added to authorized_keys."
fi

# Ensure authorized_keys file permissions are correct
if [[ -f "$SSH_DIR/authorized_keys" ]]; then
  chmod 600 "$SSH_DIR/authorized_keys"
fi

echo "SSH key setup complete."


# Update Galaxy
ansible-galaxy install -r requirements.yml

# Run playbook
echo "Running the Ansible playbook..."
if [[ -f "$CONFIG_DIR/vault-password.txt" ]]; then
  ansible-playbook --diff --extra-vars "@$CONFIG_DIR/values.yml" --vault-password-file "$CONFIG_DIR/vault-password.txt" "$DOTFILES_DIR/main.yml" "$@"
else
  ansible-playbook --diff --extra-vars "@$CONFIG_DIR/values.yml" "$DOTFILES_DIR/main.yml" "$@" --ask-become-pass 
fi
echo "Script execution completed."
