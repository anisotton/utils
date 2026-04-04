#!/bin/bash

log_info "Checking VS Code Insiders..."
if ! command -v code-insiders &> /dev/null; then
    log_warning "VS Code Insiders not found. Installing via .deb package..."

    VSCODE_DEB_URL="https://code.visualstudio.com/sha/download?build=insider&os=linux-deb-x64"
    VSCODE_TEMP_DIR=$(mktemp -d)
    VSCODE_DEB_PATH="$VSCODE_TEMP_DIR/code-insiders.deb"

    log_info "Downloading VS Code Insiders .deb package..."
    if ! curl -L -o "$VSCODE_DEB_PATH" "$VSCODE_DEB_URL"; then
        rm -rf "$VSCODE_TEMP_DIR"
        log_error "Failed to download VS Code Insiders from $VSCODE_DEB_URL"
        return 1
    fi

    log_info "Installing VS Code Insiders..."
    if [ "$EUID" -eq 0 ]; then
        dpkg -i "$VSCODE_DEB_PATH" || apt-get install -f -y
    else
        sudo dpkg -i "$VSCODE_DEB_PATH" || sudo apt-get install -f -y
    fi

    rm -rf "$VSCODE_TEMP_DIR"
    log_info "VS Code Insiders installed successfully"
else
    log_info "VS Code Insiders already installed: $(code-insiders --version | head -n 1)"
fi
