#!/bin/bash

set -e

UBUNTU_SETUP_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$UBUNTU_SETUP_PATH/lib/helpers.sh"

log_info "=========================================="
log_info "  Ubuntu Development Environment Setup"
log_info "=========================================="
log_info "Starting setup..."

# Core tools (order matters — dependencies between modules)
log_info "Installing core development tools..."
for installer in "$UBUNTU_SETUP_PATH"/install/core/*.sh; do
    source "$installer"
done

# Applications (no order dependency)
log_info "Installing applications..."
for installer in "$UBUNTU_SETUP_PATH"/install/apps/*.sh; do
    source "$installer"
done

# AI Coding Tools (interactive selection)
echo ""
echo -e "${GREEN}=== AI Coding Tools ===${NC}"
echo "Selecione quais ferramentas de IA deseja instalar:"
echo "  1) OpenCode        - Agente de IA open-source para terminal"
echo "  2) Claude Code     - CLI da Anthropic para coding"
echo "  3) GitHub Copilot  - Assistente de IA do GitHub para terminal"
echo ""
echo "Digite os números separados por espaço (ex: 1 2 3), ou 0 para nenhum:"
read -r AI_TOOLS_SELECTION

INSTALL_OPENCODE=false
INSTALL_CLAUDE=false
INSTALL_COPILOT=false

for choice in $AI_TOOLS_SELECTION; do
    case "$choice" in
        1) INSTALL_OPENCODE=true ;;
        2) INSTALL_CLAUDE=true ;;
        3) INSTALL_COPILOT=true ;;
        0) break ;;
        *) log_warning "Opção '$choice' ignorada (inválida)" ;;
    esac
done

if $INSTALL_OPENCODE; then
    source "$UBUNTU_SETUP_PATH/install/ai-tools/opencode.sh"
fi

if $INSTALL_CLAUDE; then
    source "$UBUNTU_SETUP_PATH/install/ai-tools/claude-code.sh"
fi

if $INSTALL_COPILOT; then
    source "$UBUNTU_SETUP_PATH/install/ai-tools/github-copilot.sh"
fi

# Desktop customizations (GNOME)
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    log_info "Applying desktop customizations..."
    for installer in "$UBUNTU_SETUP_PATH"/install/desktop/*.sh; do
        source "$installer"
    done
else
    log_warning "Not running GNOME desktop. Skipping desktop customizations."
fi

log_info "=========================================="
log_info "  Ubuntu setup completed successfully!"
log_info "=========================================="
log_info "IMPORTANT: Please log out and log back in (or restart) for all changes to take effect."
log_info "After restarting, your default shell will be Zsh with Oh My Zsh and the Eastwood theme."
if $INSTALL_OPENCODE || $INSTALL_CLAUDE || $INSTALL_COPILOT; then
    log_info "NOTE: As ferramentas de IA instaladas requerem configuração de API key no primeiro uso."
fi
