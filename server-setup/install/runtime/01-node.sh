#!/bin/bash

log_info "Verificando Node.js..."
if ! command -v node &> /dev/null; then
    log_warning "Node.js não encontrado. Instalando via NodeSource (LTS 22)..."
    ensure_packages ca-certificates gnupg
    run_as_user "curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -"
    apt_install_packages nodejs
    log_info "Node.js instalado: $(node --version)"
else
    log_info "Node.js já instalado: $(node --version)"
fi
