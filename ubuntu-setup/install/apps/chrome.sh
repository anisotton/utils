#!/bin/bash

log_info "Checking Google Chrome..."
if ! command -v google-chrome &> /dev/null; then
    log_warning "Google Chrome not found. Installing..."
    cd /tmp
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    if [ "$EUID" -eq 0 ]; then
        dpkg -i google-chrome-stable_current_amd64.deb || apt-get install -f -y
    else
        sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt-get install -f -y
    fi
    rm google-chrome-stable_current_amd64.deb
    log_info "Google Chrome installed successfully"
else
    log_info "Google Chrome already installed"
fi
