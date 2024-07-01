#!/usr/bin/env bash

LOG_FILE="setup_ubuntu.log"
touch "$LOG_FILE"

log_message() {
    printf "\n$1" | tee -a "$LOG_FILE"
}

cancel_execution() {
    log_message "\nScript interrupted."
    exit 1
}

trap cancel_execution INT TERM

is_installed() {
    dpkg -l | grep -q "$1"
}

install_oh_my_zsh() {
    local pkg="ohmyzsh"
    local zshrc_path="$HOME/.zshrc"

     if [ -f "$zshrc_path" ]; then
        log_message "$pkg is already installed. Skipping."
    else
        log_message "Installing $pkg..."
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
            log_message "$pkg installed successfully."
        else
            log_message "Failed to install $pkg. Exiting."
            return
        fi
    fi
}

install_vscode() {
    local pkg="code"
    local download_path="$HOME/Downloads"
    local pkg_name="code.deb"

    if command -v "$pkg" &> /dev/null; then
        log_message "$pkg is already installed. Skipping."
    else
        if ! curl -o "$download_path/$pkg_name" -L https://go.microsoft.com/fwlink/?LinkID=760868; then
            log_message "Failed to download $pkg. Exiting."
            return
        fi

        if sudo apt install "$download_path./$pkg_name"; then
            log_message "$pkg installed successfully."
        else
            log_message "Failed to install $pkg. Exiting."
            return
        fi
    fi
}

install_brave_browser() {
    local pkg="brave-browser"
    if is_installed "$pkg"; then
        log_message "$pkg is already installed. Skipping."
    else
        log_message "Installing $pkg..."
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
        sudo apt update
        if sudo apt install brave-browser -y; then
            log_message "$pkg installed successfully."
        else
            log_message "Failed to install $pkg. Exiting."
            return
        fi
    fi
}

install_spotify() {
    local pkg="spotify-client"
    local app_name="Spotify"

    if is_installed "$pkg"; then
        log_message "$app_name is already installed. Skipping."
        return 
    fi

    log_message "Downloading $app_name repository key..."
    if ! curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg; then
        log_message "Failed to download $app_name repository key."
    else
        log_message "Adding $app_name repository to sources..."
        echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

        log_message "Updating package lists..."
        sudo apt update

        log_message "Installing $app_name..."
        if sudo apt install "$pkg" -y; then
            log_message "$app_name installed successfully."
        else
            log_message "Failed to install $app_name."
        fi
    fi
}


install_docker() {
    local app_name="Docker"

    if command -v docker &> /dev/null; then
        log_message "$app_name is already installed."
        return  
    fi

    log_message "Installing $app_name..."

    sudo apt update
    sudo apt install -y \
        ca-certificates \
        gnupg \
        lsb-release

    if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; then
        log_message "Failed to download Docker's GPG key."
    else
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose

        if ! sudo groupadd docker; then
            log_message "Failed to add docker group."
        elif ! sudo usermod -aG docker "$USER"; then
            log_message "Failed to add user to docker group."
        else
            newgrp docker

            if docker run hello-world &> /dev/null; then
                log_message "$app_name has been installed successfully. A reboot may be required."
            else
                log_message "Failed to run hello-world test. Docker installation may not be complete."
            fi
        fi
    fi
}


main() {
    log_message "Setup started..."

    log_message "Checking for sudo permissions..."
    if ! sudo -v > /dev/null 2>&1; then
        log_message "This script requires sudo permissions. Exiting."
        exit 1
    fi

    log_message "You will be prompted for input."

    if sudo apt update && sudo apt upgrade -y; then
        log_message "System updated successfully."
    else
        log_message "System update failed. Exiting."
        exit 1
    fi

    local -r common_packages=(
        "git" 
        "vlc" 
        "build-essential" 
        "neofetch" 
        "htop" 
        "curl" 
        "wget"
        "clang"
        "gcc"
        "zsh"
    )

    for pkg in "${common_packages[@]}"; do
        if is_installed "$pkg"; then
            log_message "$pkg is already installed. Skipping."
        else
            log_message "Installing $pkg..."
            if sudo apt-get install -y "$pkg"; then
                log_message "$pkg installed successfully."
            else
                log_message "Failed to install $pkg."
            fi
        fi
    done

    install_oh_my_zsh
    install_brave_browser
    install_vscode
    install_spotify
    install_docker

    log_message "Setup completed successfully."
}

main "$@"
