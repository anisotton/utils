#!/bin/bash

APIDOG_ZIP_URL="https://file-assets.apidog.com/download/Apidog-linux-deb-latest.zip"
log_info "Checking ApiDog..."
if ! command -v apidog &> /dev/null && ! dpkg -l 2>/dev/null | grep -q apidog; then
    log_warning "ApiDog not found. Installing from official Linux zip..."

    APIDOG_TEMP_DIR=$(mktemp -d)
    APIDOG_ZIP_PATH="$APIDOG_TEMP_DIR/apidog.zip"

    log_info "Downloading ApiDog zip package..."
    if ! curl -L -o "$APIDOG_ZIP_PATH" "$APIDOG_ZIP_URL"; then
        rm -rf "$APIDOG_TEMP_DIR"
        log_error "Failed to download ApiDog from $APIDOG_ZIP_URL"
        return 1
    fi

    log_info "Extracting ApiDog .deb from zip..."
    if ! unzip -j -o "$APIDOG_ZIP_PATH" '*.deb' -d "$APIDOG_TEMP_DIR" > /dev/null; then
        rm -rf "$APIDOG_TEMP_DIR"
        log_error "Failed to extract ApiDog .deb from zip archive"
        return 1
    fi

    APIDOG_DEB=$(find "$APIDOG_TEMP_DIR" -name '*.deb' | head -n 1)
    if [ -z "$APIDOG_DEB" ]; then
        rm -rf "$APIDOG_TEMP_DIR"
        log_error "ApiDog zip did not contain a .deb package"
        return 1
    fi

    if [ "$EUID" -eq 0 ]; then
        dpkg -i "$APIDOG_DEB" || apt-get install -f -y
    else
        sudo dpkg -i "$APIDOG_DEB" || sudo apt-get install -f -y
    fi

    rm -rf "$APIDOG_TEMP_DIR"
    log_info "ApiDog installed successfully"
else
    log_info "ApiDog already installed"
fi
