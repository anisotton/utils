#!/bin/bash

log_info "Checking NVM..."
NVM_DIR="$REAL_HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    log_warning "NVM not found. Installing..."
    NVM_LATEST=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$NVM_LATEST" ]; then
        log_warning "Could not fetch latest NVM version from GitHub API. Falling back to v0.40.4"
        NVM_LATEST="v0.40.4"
    fi
    log_info "Installing NVM $NVM_LATEST..."
    run_as_user "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_LATEST/install.sh | bash"

    if ! grep -q 'NVM_DIR' "$REAL_HOME/.zshrc" 2>/dev/null; then
        run_as_user "echo '' >> '$REAL_HOME/.zshrc'"
        run_as_user "echo 'export NVM_DIR=\"\$HOME/.nvm\"' >> '$REAL_HOME/.zshrc'"
        run_as_user "echo '[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"' >> '$REAL_HOME/.zshrc'"
        run_as_user "echo '[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"' >> '$REAL_HOME/.zshrc'"
    fi

    log_info "NVM installed successfully"
else
    log_info "NVM already installed"
fi

log_info "Ensuring Node.js LTS (with npm) via NVM..."
ENSURE_NODE_CMD=$(cat <<'EOF'
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "NVM script not found at $NVM_DIR" >&2
    exit 1
fi
. "$NVM_DIR/nvm.sh"
nvm install --lts --latest-npm >/dev/null
nvm alias default 'lts/*' >/dev/null
nvm use default >/dev/null
EOF
)
if run_as_user "$ENSURE_NODE_CMD"; then
    log_info "Node.js LTS ensured via NVM (npm bundled). Open a new shell to use it."
else
    log_warning "Unable to ensure Node.js automatically. Run: nvm install --lts --latest-npm"
fi
