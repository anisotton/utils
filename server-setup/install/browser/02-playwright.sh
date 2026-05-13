#!/bin/bash

log_info "Verificando Playwright..."
if ! run_as_user "command -v playwright &> /dev/null"; then
    log_warning "Playwright não encontrado. Instalando..."
    run_as_user "npm install -g playwright"
    log_info "Instalando Chromium via Playwright..."
    run_as_user "playwright install chromium --with-deps"
    log_info "Playwright instalado com sucesso"
else
    log_info "Playwright já instalado: $(run_as_user 'playwright --version 2>/dev/null' || echo 'versão indisponível')"
fi
