#!/bin/bash

log_info "Checking OpenCode..."
if ! command -v opencode &> /dev/null; then
    log_warning "OpenCode not found. Installing..."
    if run_as_user "curl -fsSL https://opencode.ai/install | bash"; then
        log_info "OpenCode installed successfully"
    else
        log_warning "Failed to install OpenCode automatically. Run manually: curl -fsSL https://opencode.ai/install | bash"
    fi
else
    log_info "OpenCode already installed: $(opencode --version 2>/dev/null || echo 'version check unavailable')"
fi
