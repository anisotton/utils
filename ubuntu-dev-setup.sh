#!/bin/bash

# =============================================================================
# UBUNTU DEVELOPMENT SETUP SCRIPT
# =============================================================================
# Este script automatiza a instalação e configuração do ambiente de
# desenvolvimento para Ubuntu. Os seguintes softwares serão instalados:
#
#  1.  Google Chrome          - Navegador web
#  2.  Zsh + Oh My Zsh        - Shell aprimorado com plugins
#  3.  NVM + Node.js LTS      - Gerenciador de versões Node.js
#  4.  PHP + Composer         - Linguagem PHP e gerenciador de dependências
#  5.  Docker + Docker Compose- Containerização
#  6.  Valet Linux            - Ambiente de desenvolvimento PHP local
#  7.  Takeout                - Gerenciador de serviços Docker (MySQL, Redis, etc.)
#  8.  Micro                  - Editor de texto moderno para terminal
#  9.  VS Code Insiders       - Editor de código
# 10.  DBeaver                - Cliente de banco de dados universal
# 11.  ApiDog                 - Cliente de API (alternativa ao Postman)
#
# Configurações adicionais:
#  - Customização do Ubuntu Dock (posição, auto-hide, ícones)
#  - Desativação do Apache (para evitar conflitos com Valet)
#  - Plugins Zsh: autosuggestions, syntax-highlighting, git, docker, etc.
#
# Uso: sudo ./ubuntu-dev-setup.sh
# =============================================================================

set -e

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
if [ "$EUID" -eq 0 ]; then
    if [ -z "$SUDO_USER" ]; then
        log_error "Running as root without sudo. Please run with: sudo ./ubuntu-dev-setup.sh"
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

# Function to run command as real user
run_as_user() {
    if [ "$EUID" -eq 0 ]; then
        sudo -u "$SUDO_USER" -H bash -c "cd '$REAL_HOME' && $1"
    else
        bash -c "$1"
    fi
}

log_info "Starting Ubuntu Development Setup..."

# 1. Google Chrome
log_info "Checking Google Chrome..."
if ! command -v google-chrome &> /dev/null; then
    log_warning "Google Chrome not found. Installing..."
    cd /tmp
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    if [ "$EUID" -eq 0 ]; then
        dpkg -i google-chrome-stable_current_amd64.deb || apt-get install -f -y
    else
        sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt-get install -f -y
    fi
    rm google-chrome-stable_current_amd64.deb
    log_info "Google Chrome installed successfully"
else
    log_info "Google Chrome already installed"
fi

# 2. Zsh and Oh My Zsh
log_info "Checking Zsh..."
if ! command -v zsh &> /dev/null; then
    log_warning "Zsh not found. Installing..."
    if [ "$EUID" -eq 0 ]; then
        apt-get update
        apt-get install -y zsh
    else
        sudo apt-get update
        sudo apt-get install -y zsh
    fi
    log_info "Zsh installed successfully"
else
    log_info "Zsh already installed"
fi

log_info "Setting Zsh as default shell..."
CURRENT_SHELL=$(run_as_user "echo \$SHELL")
TARGET_ZSH="$(command -v zsh)"
if [ "$CURRENT_SHELL" != "$TARGET_ZSH" ]; then
    if [ "$EUID" -eq 0 ]; then
        if chsh -s "$TARGET_ZSH" "$REAL_USER"; then
            log_info "Default shell updated to Zsh for $REAL_USER"
        else
            log_warning "Failed to set Zsh as default shell automatically. Run manually: chsh -s $TARGET_ZSH $REAL_USER"
        fi
    else
        log_warning "Run manually to set Zsh as default shell: chsh -s $TARGET_ZSH"
    fi
else
    log_info "Zsh is already the default shell"
fi

log_info "Checking Oh My Zsh..."
if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
    log_warning "Oh My Zsh not found. Installing..."
    run_as_user 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    log_info "Oh My Zsh installed successfully"
else
    log_info "Oh My Zsh already installed"
fi

log_info "Setting Eastwood theme..."
log_info "Eastwood is a built-in Oh My Zsh theme"

log_info "Installing Zsh plugins..."
if [ ! -d "$REAL_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    run_as_user "git clone https://github.com/zsh-users/zsh-autosuggestions '$REAL_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions'"
    log_info "zsh-autosuggestions installed"
else
    log_info "zsh-autosuggestions already installed"
fi

if [ ! -d "$REAL_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    run_as_user "git clone https://github.com/zsh-users/zsh-syntax-highlighting '$REAL_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting'"
    log_info "zsh-syntax-highlighting installed"
else
    log_info "zsh-syntax-highlighting already installed"
fi

log_info "Configuring .zshrc..."
if [ -f "$REAL_HOME/.zshrc" ]; then
    run_as_user "sed -i 's/^ZSH_THEME=.*/ZSH_THEME=\"eastwood\"/' '$REAL_HOME/.zshrc'"
    
    if ! grep -q 'plugins=(git docker docker-compose npm composer sudo web-search z zsh-autosuggestions zsh-syntax-highlighting)' "$REAL_HOME/.zshrc"; then
        run_as_user "sed -i 's/^plugins=.*/plugins=(git docker docker-compose npm composer sudo web-search z zsh-autosuggestions zsh-syntax-highlighting)/' '$REAL_HOME/.zshrc'"
    fi
    
    if ! grep -q 'alias_zsh.txt' "$REAL_HOME/.zshrc"; then
        run_as_user "echo '' >> '$REAL_HOME/.zshrc'"
        run_as_user "echo '[ -f ~/IsottonTecnologia/Comandos/alias_zsh.txt ] && source ~/IsottonTecnologia/Comandos/alias_zsh.txt' >> '$REAL_HOME/.zshrc'"
    fi
    log_info ".zshrc configured"
fi

# 3. NVM
log_info "Checking NVM..."
NVM_DIR="$REAL_HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    log_warning "NVM not found. Installing..."
    run_as_user "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
    
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

# 4. PHP and Composer
log_info "Checking PHP..."
if ! command -v php &> /dev/null; then
    log_warning "PHP not found. Installing..."
    if [ "$EUID" -eq 0 ]; then
        apt-get install -y php php-cli php-fpm php-mysql php-xml php-mbstring php-curl php-zip php-gd php-intl
    else
        sudo apt-get install -y php php-cli php-fpm php-mysql php-xml php-mbstring php-curl php-zip php-gd php-intl
    fi
    log_info "PHP installed successfully"
else
    log_info "PHP already installed: $(php -v | head -n 1)"
fi

log_info "Validating PHP version for Valet (requires >= 5.6)..."
if php -r 'exit(version_compare(PHP_VERSION, "5.6", ">=") ? 0 : 1);'; then
    log_info "PHP version requirements satisfied"
else
    log_error "PHP version $(php -v | head -n1) is lower than 5.6. Please upgrade PHP before continuing."
    exit 1
fi

log_info "Ensuring required PHP extensions for Valet..."
ensure_packages php-cli php-curl php-mbstring php-xml php-zip php-sqlite3 php-mysql php-pgsql php-intl
if apt-cache show php-mcrypt >/dev/null 2>&1; then
    ensure_packages php-mcrypt
else
    log_warning "php-mcrypt package not available on this Ubuntu release. Valet no longer depends on it, continuing."
fi

log_info "Checking Composer..."
if ! command -v composer &> /dev/null; then
    log_warning "Composer not found. Installing..."
    cd /tmp
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --quiet
    if [ "$EUID" -eq 0 ]; then
        mv composer.phar /usr/local/bin/composer
        chmod +x /usr/local/bin/composer
    else
        sudo mv composer.phar /usr/local/bin/composer
        sudo chmod +x /usr/local/bin/composer
    fi
    rm -f composer-setup.php
    log_info "Composer installed successfully"
else
    COMPOSER_VERSION=$(timeout 5 composer --version --no-ansi 2>/dev/null | head -n 1 || echo "version check timed out")
    log_info "Composer already installed: $COMPOSER_VERSION"
fi

# 5. Docker
log_info "Checking Docker..."
if ! command -v docker &> /dev/null; then
    log_warning "Docker not found. Installing..."
    if [ "$EUID" -eq 0 ]; then
        apt-get update
        apt-get install -y ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        usermod -aG docker $REAL_USER
    else
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        sudo usermod -aG docker $REAL_USER
    fi
    log_info "Docker installed successfully. You need to log out and back in for group changes to take effect."
else
    log_info "Docker already installed: $(docker --version)"
    
    if ! groups $REAL_USER | grep -q docker; then
        if [ "$EUID" -eq 0 ]; then
            usermod -aG docker $REAL_USER
        else
            sudo usermod -aG docker $REAL_USER
        fi
        log_warning "Added user to docker group. Please log out and back in."
    fi
fi

# Ensure Composer global bin is in PATH
COMPOSER_BIN="$REAL_HOME/.config/composer/vendor/bin"
if ! grep -q '.config/composer/vendor/bin' "$REAL_HOME/.zshrc" 2>/dev/null; then
    run_as_user "echo 'export PATH=\"\$HOME/.config/composer/vendor/bin:\$PATH\"' >> '$REAL_HOME/.zshrc'"
fi

# 6. Apache HTTP Server (disable for Valet)
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

# 7. Valet Linux
log_info "Ensuring Valet Linux OS dependencies (network-manager, libnss3-tools, jq, xsel)..."
ensure_packages network-manager libnss3-tools jq xsel

log_info "Checking Valet Linux..."
if ! run_as_user "command -v valet" &> /dev/null; then
    log_warning "Valet Linux not found. Installing dependencies and Valet..."
    
    log_info "Installing Valet via Composer (this may take a while)..."
    run_as_user "COMPOSER_ALLOW_SUPERUSER=1 composer global require cpriego/valet-linux --no-interaction"
    
    if run_as_user "export PATH=\"$COMPOSER_BIN:\$PATH\" && command -v valet" &> /dev/null; then
        log_info "Running valet install..."
        run_as_user "export PATH=\"$COMPOSER_BIN:\$PATH\" && valet install"
        log_info "Valet Linux installed and configured"
    else
        log_error "Valet command not found after installation. Please check PATH and run 'valet install' manually."
    fi
else
    log_info "Valet Linux already installed"
fi

# 8. Takeout
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

# 9. Micro Editor
log_info "Checking Micro editor..."
if ! command -v micro &> /dev/null; then
    log_warning "Micro editor not found. Installing..."
    if [ "$EUID" -eq 0 ]; then
        apt-get update
        apt-get install -y micro
    else
        sudo apt-get update
        sudo apt-get install -y micro
    fi
    log_info "Micro editor installed successfully"
else
    log_info "Micro editor already installed: $(micro --version | head -n 1)"
fi

# 10. Customização de UI (Ubuntu Dock)
log_info "Applying Ubuntu Dock customization..."
if ! command -v gsettings &> /dev/null; then
    log_warning "gsettings not available. Skipping Dock customization."
else
    USER_DBUS_SOCKET="/run/user/$(id -u "$REAL_USER")/bus"
    if [ ! -S "$USER_DBUS_SOCKET" ]; then
        log_warning "Could not find session bus for $REAL_USER at $USER_DBUS_SOCKET. Skip Dock customization and run commands after logging into GNOME."
    else
        USER_DBUS_ADDRESS="unix:path=$USER_DBUS_SOCKET"
        DISPLAY_VALUE="${DISPLAY:-:0}"

        if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'"; then
            log_info "Dock positioned at the bottom"
        else
            log_warning "Failed to reposition Dock. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'"
        fi

        if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false"; then
            log_info "Dock stretch disabled"
        else
            log_warning "Failed to disable Dock stretch. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false"
        fi

        if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true"; then
            log_info "Dock enabled on all monitors"
        else
            log_warning "Failed to enable Dock on all monitors. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true"
        fi

        if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false"; then
            log_info "Dock will auto-hide when not focused"
        else
            log_warning "Failed to enable Dock auto-hide. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false"
        fi

        if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock autohide true"; then
            log_info "Dock autohide preference enforced"
        else
            log_warning "Failed to set Dock autohide. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock autohide true"
        fi

        if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 36"; then
            log_info "Dock icon size set to 36px"
        else
            log_warning "Failed to set Dock icon size. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 36"
        fi
    fi
fi

# 11. VS Code Insiders
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
        exit 1
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

# 12. DBeaver
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

# 13. ApiDog
APIDOG_ZIP_URL="https://file-assets.apidog.com/download/Apidog-linux-deb-latest.zip"
log_info "Checking ApiDog..."
if ! command -v apidog &> /dev/null && ! dpkg -l 2>/dev/null | grep -q apidog; then
    log_warning "ApiDog not found. Installing from official Linux zip..."

    if ! command -v unzip &> /dev/null; then
        log_info "Installing unzip dependency for ApiDog package..."
        if [ "$EUID" -eq 0 ]; then
            apt-get update && apt-get install -y unzip
        else
            sudo apt-get update && sudo apt-get install -y unzip
        fi
    fi

    APIDOG_TEMP_DIR=$(mktemp -d)
    APIDOG_ZIP_PATH="$APIDOG_TEMP_DIR/apidog.zip"

    log_info "Downloading ApiDog zip package..."
    if ! curl -L -o "$APIDOG_ZIP_PATH" "$APIDOG_ZIP_URL"; then
        rm -rf "$APIDOG_TEMP_DIR"
        log_error "Failed to download ApiDog from $APIDOG_ZIP_URL"
        exit 1
    fi

    log_info "Extracting ApiDog .deb from zip..."
    if ! unzip -j -o "$APIDOG_ZIP_PATH" '*.deb' -d "$APIDOG_TEMP_DIR" > /dev/null; then
        rm -rf "$APIDOG_TEMP_DIR"
        log_error "Failed to extract ApiDog .deb from zip archive"
        exit 1
    fi

    APIDOG_DEB=$(find "$APIDOG_TEMP_DIR" -name '*.deb' | head -n 1)
    if [ -z "$APIDOG_DEB" ]; then
        rm -rf "$APIDOG_TEMP_DIR"
        log_error "ApiDog zip did not contain a .deb package"
        exit 1
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

log_info "=========================================="
log_info "Setup completed successfully!"
log_info "=========================================="
log_info "IMPORTANT: Please log out and log back in (or restart) for all changes to take effect."
log_info "After restarting, your default shell will be Zsh with Oh My Zsh and the Eastwood theme."
