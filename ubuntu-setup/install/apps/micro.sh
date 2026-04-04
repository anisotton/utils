#!/bin/bash

log_info "Checking Micro editor..."
if ! command -v micro &> /dev/null; then
    log_warning "Micro editor not found. Installing..."
    if [ "$EUID" -eq 0 ]; then
        apt-get update
        apt-get install -y micro
    else
        sudo apt-get update
        sudo apt-get install -y micro
    fi
    log_info "Micro editor installed successfully"
else
    log_info "Micro editor already installed: $(micro --version | head -n 1)"
fi
