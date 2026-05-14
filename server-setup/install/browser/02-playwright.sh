#!/bin/bash

log_info "Verificando Playwright..."
if ! command -v playwright &> /dev/null; then
    log_warning "Playwright não encontrado. Instalando..."

    # npm -g escreve em /usr/lib/node_modules (root-owned quando Node vem do NodeSource)
    if [ "$EUID" -eq 0 ]; then
        npm install -g playwright
        # apt-deps do sistema precisam de root
        playwright install-deps chromium
        # browsers vão pro cache do usuário real, não /root/.cache
        run_as_user "playwright install chromium"
    else
        sudo npm install -g playwright
        sudo playwright install-deps chromium
        playwright install chromium
    fi

    log_info "Playwright instalado com sucesso"
else
    log_info "Playwright já instalado: $(playwright --version 2>/dev/null || echo 'versão indisponível')"
fi
