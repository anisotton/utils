#!/bin/bash

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
TARGET_ZSH="$(command -v zsh)"
CURRENT_SHELL=$(run_as_user 'grep "^$(whoami):" /etc/passwd | cut -d: -f7' 2>/dev/null || echo "")
if [ -z "$CURRENT_SHELL" ]; then
    CURRENT_SHELL=$(run_as_user "echo \$SHELL")
fi
if [ "$CURRENT_SHELL" != "$TARGET_ZSH" ]; then
    if [ "$EUID" -eq 0 ]; then
        if chsh -s "$TARGET_ZSH" "$REAL_USER" 2>/dev/null; then
            log_info "Default shell updated to Zsh for $REAL_USER"
        else
            log_warning "chsh failed. Trying usermod..."
            usermod -s "$TARGET_ZSH" "$REAL_USER" && log_info "Default shell updated to Zsh for $REAL_USER" || log_warning "Failed to set Zsh as default shell. Run manually: sudo chsh -s $TARGET_ZSH $REAL_USER"
        fi
    else
        if sudo chsh -s "$TARGET_ZSH" "$REAL_USER" 2>/dev/null; then
            log_info "Default shell updated to Zsh for $REAL_USER"
        else
            log_warning "chsh failed. Trying usermod..."
            sudo usermod -s "$TARGET_ZSH" "$REAL_USER" && log_info "Default shell updated to Zsh for $REAL_USER" || log_warning "Failed to set Zsh as default shell. Run manually: sudo chsh -s $TARGET_ZSH $REAL_USER"
        fi
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

    # Uncomment the default Oh My Zsh PATH line if it exists commented out
    if grep -q '^# export PATH=\$HOME/bin:\$HOME/\.local/bin' "$REAL_HOME/.zshrc"; then
        run_as_user "sed -i 's|^# export PATH=\$HOME/bin:\$HOME/\.local/bin|export PATH=\$HOME/bin:\$HOME/.local/bin|' '$REAL_HOME/.zshrc'"
    elif ! grep -q '^[^#]*\.local/bin' "$REAL_HOME/.zshrc"; then
        # If no active .local/bin PATH entry exists, add one
        run_as_user "echo '' >> '$REAL_HOME/.zshrc'"
        run_as_user "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> '$REAL_HOME/.zshrc'"
    fi

    log_info ".zshrc configured"
fi
