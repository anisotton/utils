#!/bin/bash

log_info "Checking Apache service to avoid Valet conflicts..."
if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files 2>/dev/null | grep -q '^apache2\.service'; then
    SYSTEMCTL_CMD="systemctl"
    if [ "$EUID" -ne 0 ]; then
        SYSTEMCTL_CMD="sudo systemctl"
    fi

    if $SYSTEMCTL_CMD is-active --quiet apache2; then
        if $SYSTEMCTL_CMD stop apache2; then
            log_info "Apache service stopped"
        else
            log_warning "Failed to stop Apache service automatically. Run: sudo systemctl stop apache2"
        fi
    else
        log_info "Apache service already stopped"
    fi

    if $SYSTEMCTL_CMD is-enabled --quiet apache2; then
        if $SYSTEMCTL_CMD disable apache2; then
            log_info "Apache service disabled at boot"
        else
            log_warning "Failed to disable Apache service. Run: sudo systemctl disable apache2"
        fi
    else
        log_info "Apache service already disabled"
    fi

    if $SYSTEMCTL_CMD mask apache2; then
        log_info "Apache service masked to prevent accidental restarts"
    else
        log_warning "Failed to mask Apache service. Run: sudo systemctl mask apache2"
    fi
else
    log_info "Apache service not detected; continuing"
fi

log_info "Ensuring Valet Linux OS dependencies (network-manager, libnss3-tools, jq, xsel)..."
ensure_packages network-manager libnss3-tools jq xsel

log_info "Checking Valet Linux..."
if ! run_as_user "command -v valet" &> /dev/null; then
    log_warning "Valet Linux not found. Installing dependencies and Valet..."

    log_info "Installing Valet via Composer (this may take a while)..."
    run_as_user "COMPOSER_ALLOW_SUPERUSER=1 composer global require cpriego/valet-linux --no-interaction"

    if run_as_user "export PATH=\"$COMPOSER_BIN:\$PATH\" && command -v valet" &> /dev/null; then
        PORT80_PID=$(lsof -ti:80 2>/dev/null || true)
        if [ -n "$PORT80_PID" ]; then
            PORT80_PROCESS=$(ps -p "$PORT80_PID" -o comm= 2>/dev/null || echo "unknown")
            log_warning "Port 80 is in use by '$PORT80_PROCESS' (PID $PORT80_PID). Valet needs port 80 free."
            log_warning "Attempting to stop the process..."
            if [ "$EUID" -eq 0 ]; then
                kill "$PORT80_PID" 2>/dev/null || true
            else
                sudo kill "$PORT80_PID" 2>/dev/null || true
            fi
            sleep 2
            if lsof -ti:80 &>/dev/null; then
                log_error "Port 80 still in use. Please free it manually before running 'valet install'."
            else
                log_info "Port 80 is now free"
            fi
        fi
        log_info "Running valet install..."
        run_as_user "export PATH=\"$COMPOSER_BIN:\$PATH\" && valet install"
        log_info "Valet Linux installed and configured"
    else
        log_error "Valet command not found after installation. Please check PATH and run 'valet install' manually."
    fi
else
    log_info "Valet Linux already installed"
fi
