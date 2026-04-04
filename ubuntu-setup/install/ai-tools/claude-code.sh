#!/bin/bash

log_info "Checking Claude Code..."
if ! command -v claude &> /dev/null; then
    log_warning "Claude Code not found. Installing..."
    if run_as_user "curl -fsSL https://claude.ai/install.sh | bash"; then
        log_info "Claude Code installed successfully"
    else
        log_warning "Failed to install Claude Code automatically. Run manually: curl -fsSL https://claude.ai/install.sh | bash"
    fi
else
    log_info "Claude Code already installed: $(claude --version 2>/dev/null || echo 'version check unavailable')"
fi

install_agent_skills "$REAL_HOME/.claude/skills"
