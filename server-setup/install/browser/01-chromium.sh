#!/bin/bash

log_info "Verificando Chromium..."
if ! command -v chromium-browser &> /dev/null && ! command -v chromium &> /dev/null; then
    log_warning "Chromium não encontrado. Instalando..."
    ensure_packages chromium-browser chromium-chromedriver
    log_info "Chromium instalado com sucesso"
else
    log_info "Chromium já instalado"
fi
