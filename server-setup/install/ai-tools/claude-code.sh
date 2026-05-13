#!/bin/bash

log_info "Verificando Claude Code..."
if ! command -v claude &> /dev/null; then
    log_warning "Claude Code não encontrado. Instalando..."
    if run_as_user "curl -fsSL https://claude.ai/install.sh | bash"; then
        log_info "Claude Code instalado com sucesso"
    else
        log_warning "Falha ao instalar Claude Code automaticamente. Execute manualmente: curl -fsSL https://claude.ai/install.sh | bash"
    fi
else
    log_info "Claude Code já instalado: $(claude --version 2>/dev/null || echo 'versão indisponível')"
fi

install_agent_skills "$REAL_HOME/.claude/skills"
