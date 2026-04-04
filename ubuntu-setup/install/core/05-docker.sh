#!/bin/bash

log_info "Checking Docker..."
if ! command -v docker &> /dev/null; then
    log_warning "Docker not found. Installing..."

    log_info "Removing conflicting Docker packages (if any)..."
    CONFLICTING_PKGS=(docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc)
    PKGS_TO_REMOVE=()
    for pkg in "${CONFLICTING_PKGS[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            PKGS_TO_REMOVE+=("$pkg")
        fi
    done
    if [ ${#PKGS_TO_REMOVE[@]} -gt 0 ]; then
        log_warning "Removing conflicting packages: ${PKGS_TO_REMOVE[*]}"
        if [ "$EUID" -eq 0 ]; then
            apt-get remove -y "${PKGS_TO_REMOVE[@]}"
        else
            sudo apt-get remove -y "${PKGS_TO_REMOVE[@]}"
        fi
    else
        log_info "No conflicting Docker packages found"
    fi

    if [ "$EUID" -eq 0 ]; then
        apt-get update
        apt-get install -y ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null

        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        usermod -aG docker $REAL_USER
    else
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        sudo usermod -aG docker $REAL_USER
    fi
    log_info "Docker installed successfully. You need to log out and back in for group changes to take effect."
else
    log_info "Docker already installed: $(docker --version)"

    if ! groups $REAL_USER | grep -q docker; then
        if [ "$EUID" -eq 0 ]; then
            usermod -aG docker $REAL_USER
        else
            sudo usermod -aG docker $REAL_USER
        fi
        log_warning "Added user to docker group. Please log out and back in."
    fi
fi
