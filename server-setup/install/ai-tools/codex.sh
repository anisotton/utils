#!/bin/bash

log_info "Verificando Codex CLI..."
if ! command -v codex &> /dev/null; then
    log_warning "Codex não encontrado. Instalando..."
    if run_as_user "npm install -g @openai/codex"; then
        log_info "Codex instalado com sucesso"
    else
        log_warning "Falha ao instalar Codex. Execute manualmente: npm install -g @openai/codex"
    fi
else
    log_info "Codex já instalado: $(codex --version 2>/dev/null || echo 'versão indisponível')"
fi
