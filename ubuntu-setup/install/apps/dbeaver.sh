#!/bin/bash

log_info "Checking DBeaver..."
if ! snap list dbeaver-ce &> /dev/null 2>&1; then
    log_warning "DBeaver not found. Installing..."
    if [ "$EUID" -eq 0 ]; then
        snap install dbeaver-ce
    else
        sudo snap install dbeaver-ce
    fi
    log_info "DBeaver installed successfully"
else
    log_info "DBeaver already installed"
fi
