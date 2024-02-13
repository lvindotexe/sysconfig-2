#!/bin/bash

set -e

# Repository URL
REPO_URL="https://github.com/your/repository.git"
# Initialize DEST_FOLDER with a hardcoded value
DEST_FOLDER="sysconfig-2"
# The extra_args variable will be set based on the current non-root user
extra_args=""

# Check if the script is running as root and warn the user
if [ "$(id -u)" -eq 0 ]; then
    echo "Warning: It's not recommended to run this script as root."
else
    # Set extra_args to use the current user for Ansible
    extra_args="-e ansible_user=$(whoami)"
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
    if [ -d "$DEST_FOLDER" ]; then
        echo "Repository folder exists. Checking for updates..."
        cd "$DEST_FOLDER"
        git fetch
        if git status | grep -q "Your branch is behind"; then
            echo "Repository is behind. Pulling changes..."
            git pull
            return 0
        else
            echo "Repository is up to date."
            return 1
        fi
    else
        echo "Cloning the repository..."
        git clone "$REPO_URL" "$DEST_FOLDER" || { echo "Failed to clone repository."; exit 1; }
        cd "$DEST_FOLDER"
        return 0
    fi
}

# Update or clone the repository
update_or_clone_repo
repo_updated=$?

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

# Run the playbook with extra_args if the repository was updated or freshly cloned
if [ $repo_updated -eq 0 ]; then
    echo "Running the Ansible playbook..."
    ansible-playbook local.yml $extra_args
else
    echo "No updates. Skipping playbook execution."
fi

echo "Script execution completed."