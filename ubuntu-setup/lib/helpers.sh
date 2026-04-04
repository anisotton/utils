#!/bin/bash

# =============================================================================
# SHARED HELPER FUNCTIONS
# =============================================================================
# Sourced by all installer modules. Provides logging, package management,
# and user detection utilities.
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

apt_install_packages() {
    local packages=("$@")
    if [ ${#packages[@]} -eq 0 ]; then
        return
    fi
    if [ "$EUID" -eq 0 ]; then
        apt-get update >/dev/null 2>&1
        apt-get install -y "${packages[@]}"
    else
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y "${packages[@]}"
    fi
}

ensure_packages() {
    local missing=()
    for pkg in "$@"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        log_info "Installing missing packages: ${missing[*]}"
        apt_install_packages "${missing[@]}"
    fi
}

# Detect if running with sudo and get real user
setup_user_detection() {
    if [ "$EUID" -eq 0 ]; then
        if [ -z "$SUDO_USER" ]; then
            log_error "Running as root without sudo. Please run with: sudo ./install.sh"
            exit 1
        fi
        REAL_USER="$SUDO_USER"
        REAL_HOME=$(eval echo ~$SUDO_USER)
        log_info "Running with sudo as user: $REAL_USER"
    else
        REAL_USER="$USER"
        REAL_HOME="$HOME"
        log_warning "Not running with sudo. Some installations may ask for password."
    fi

    COMPOSER_BIN="$REAL_HOME/.config/composer/vendor/bin"
}

# Run command as the real user (not root)
run_as_user() {
    if [ "$EUID" -eq 0 ]; then
        sudo -u "$SUDO_USER" -H bash -c "cd '$REAL_HOME' && $1"
    else
        bash -c "$1"
    fi
}

# Usage: install_agent_skills "/target/skills/dir"
# Symlinks the entire skills folder so new skills are picked up automatically
install_agent_skills() {
    local target_dir="$1"
    local skills_src
    skills_src="$(cd "$UBUNTU_SETUP_PATH/../skills" 2>/dev/null && pwd)"

    if [ ! -d "$skills_src" ]; then
        log_warning "Skills source directory not found: $UBUNTU_SETUP_PATH/../skills"
        return 1
    fi

    run_as_user "rm -rf '$target_dir' && ln -s '$skills_src' '$target_dir'"
    log_info "Agent skills linked dynamically: $target_dir -> $skills_src"
}

# Initialize user detection on source
setup_user_detection
