#!/bin/bash

TAKEOUT_DOCKER_CMD='docker run --rm -v /var/run/docker.sock:/var/run/docker.sock --add-host=host.docker.internal:host-gateway -it tighten/takeout:latest'
log_info "Configuring Takeout alias (Docker-based install per docs)..."

if [ ! -f "$REAL_HOME/.zshrc" ]; then
    run_as_user "touch '$REAL_HOME/.zshrc'"
fi

TAKEOUT_ALIAS="alias takeout=\"/usr/local/bin/takeout\""
if run_as_user "grep -q '^alias takeout=' '$REAL_HOME/.zshrc'"; then
    run_as_user "sed -i 's|^alias takeout=.*|$TAKEOUT_ALIAS|' '$REAL_HOME/.zshrc'"
    log_info "Updated existing takeout alias to use wrapper"
else
    run_as_user "cat <<'EOF' >> '$REAL_HOME/.zshrc'

# Takeout alias (Docker wrapper for tighten/takeout:latest)
$TAKEOUT_ALIAS
EOF"
    log_info "Added Takeout alias to .zshrc"
fi

log_info "Ensuring takeout command wrapper is available..."
TAKEOUT_WRAPPER="/usr/local/bin/takeout"
TAKEOUT_WRAPPER_CONTENT=$(cat <<'EOF'
#!/bin/bash
TAKEOUT_CMD=(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock --add-host=host.docker.internal:host-gateway -it tighten/takeout:latest)
if [ "$EUID" -eq 0 ] || id -nG "$USER" | grep -qw docker; then
    exec "${TAKEOUT_CMD[@]}" "$@"
elif command -v sudo > /dev/null 2>&1; then
    echo "[Takeout] Docker group access not detected. Using sudo to reach the Docker socket..." >&2
    exec sudo "${TAKEOUT_CMD[@]}" "$@"
else
    echo "[Takeout] Docker access requires sudo or membership in the docker group." >&2
    echo "Add your user to the docker group and re-login, or install sudo." >&2
    exit 1
fi
EOF
)

if [ "$EUID" -eq 0 ]; then
    printf "%s" "$TAKEOUT_WRAPPER_CONTENT" > "$TAKEOUT_WRAPPER"
    chmod +x "$TAKEOUT_WRAPPER"
else
    printf "%s" "$TAKEOUT_WRAPPER_CONTENT" | sudo tee "$TAKEOUT_WRAPPER" > /dev/null
    sudo chmod +x "$TAKEOUT_WRAPPER"
fi
log_info "Takeout wrapper script installed at $TAKEOUT_WRAPPER"

log_info "Pulling latest tighten/takeout Docker image..."
if docker --version &> /dev/null; then
    if [ "$EUID" -eq 0 ] || groups "$REAL_USER" | grep -q docker; then
        if docker pull tighten/takeout:latest; then
            log_info "Docker image tighten/takeout:latest ready for use"
        else
            log_warning "Unable to pull tighten/takeout:latest automatically. Run: docker pull tighten/takeout:latest"
        fi
    else
        log_warning "Current user lacks Docker permissions. After relogin, run: docker pull tighten/takeout:latest"
    fi
else
    log_warning "Docker CLI not available; Takeout alias will work after Docker is installed."
fi
