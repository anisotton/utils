#!/bin/bash

log_info "Verificando Node.js..."
if ! command -v node &> /dev/null; then
    log_warning "Node.js não encontrado. Instalando via NodeSource (LTS 22)..."
    ensure_packages ca-certificates gnupg
    if [ "$EUID" -eq 0 ]; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    else
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    fi
    apt_install_packages nodejs
    log_info "Node.js instalado: $(node --version)"
else
    log_info "Node.js já instalado: $(node --version)"
fi
