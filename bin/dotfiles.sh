#!/bin/sh

set -e

# Paths
CONFIG_DIR="$HOME/.config/dotfiles"
DOTFILES_DIR="$HOME/.dotfiles"
SSH_DIR="$HOME/.ssh"
VALUES_FILE="$HOME/.config/dotfiles/values.yml"

# Check if the script is running as root and warn the user
if [ "$(id -u)" -eq 0 ]; then
    echo "Warning: It's not recommended to run this script as root."
    exit 1
fi

# Check for the existence of values.yml in the current directory
if [ ! -f "$VALUES_FILE" ]; then
  echo "The file $VALUES_FILE does not exist. Please create it, in this format
    git_user_name: \$user
    git_user_email: \$email
  "
  exit 1
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

# Check for Ansible and install if not present
if ! command -v ansible >/dev/null 2>&1; then
    echo "Ansible is not installed. Attempting to install Ansible..."
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|pop)
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
if [ -f "$SSH_DIR/id_rsa" ] && [ -f "$SSH_DIR/id_rsa.pub" ]; then
  echo "Existing SSH keys found. Using them."
  chmod 700 "$SSH_DIR"
  if ! grep -qF "$(cat "$SSH_DIR/id_rsa.pub")" "$SSH_DIR/authorized_keys" 2>/dev/null; then
    cat "$SSH_DIR/id_rsa.pub" >> "$SSH_DIR/authorized_keys"
    echo "Public key added to authorized_keys."
  else
    echo "Public key already in authorized_keys."
  fi
else
  echo "No existing SSH keys found. Generating new keys."
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  ssh-keygen -b 4096 -t rsa -f "$SSH_DIR/id_rsa" -N "" -C "$USER@$HOSTNAME"
  cat "$SSH_DIR/id_rsa.pub" >> "$SSH_DIR/authorized_keys"
  echo "New SSH keys generated and added to authorized_keys."
fi

if [ -f "$SSH_DIR/authorized_keys" ]; then
  chmod 600 "$SSH_DIR/authorized_keys"
fi

echo "SSH key setup complete."

ansible-galaxy install -r requirements.yml

echo "Running the Ansible playbook..."
if [ -f "$CONFIG_DIR/vault-password.txt" ]; then
  ansible-playbook --diff --extra-vars "@$CONFIG_DIR/values.yml" --vault-password-file "$CONFIG_DIR/vault-password.txt" "$DOTFILES_DIR/main.yml" "$@"
else
  ansible-playbook --diff --extra-vars "@$CONFIG_DIR/values.yml" "$DOTFILES_DIR/main.yml" "$@" --ask-become-pass 
fi
echo "Script execution completed."