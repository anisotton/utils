#!/bin/bash

log_info "Checking GitHub Copilot CLI..."
if ! command -v copilot &> /dev/null; then
    log_warning "GitHub Copilot CLI not found. Installing..."
    if run_as_user "curl -fsSL https://gh.io/copilot-install | bash"; then
        log_info "GitHub Copilot CLI installed successfully"
    else
        log_warning "Failed to install GitHub Copilot CLI automatically. Run manually: curl -fsSL https://gh.io/copilot-install | bash"
    fi
else
    log_info "GitHub Copilot CLI already installed"
fi

install_agent_skills "$REAL_HOME/.copilot/skills"
