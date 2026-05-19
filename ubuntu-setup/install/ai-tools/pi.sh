#!/bin/bash

log_info "Verificando Pi Coding Agent..."

if ! command -v pi &> /dev/null; then
    log_warning "Pi não encontrado. Instalando via npm..."
    if run_as_user "npm install -g @mariozechner/pi-coding-agent"; then
        log_info "Pi instalado com sucesso."
    else
        log_warning "Falha ao instalar Pi. Execute manualmente: npm install -g @mariozechner/pi-coding-agent"
        return 0 2>/dev/null || exit 0
    fi
else
    log_info "Pi já instalado: $(pi --version 2>/dev/null || echo 'versão indisponível')"
fi

# Configuração opcional com Ollama
echo ""
echo "Deseja configurar o Pi para usar um servidor Ollama local?"
echo "  (Enter para pular)"
read -r OLLAMA_HOST_INPUT

if [ -n "$OLLAMA_HOST_INPUT" ]; then
    PI_CONFIG_DIR="$REAL_HOME/.pi/agent"
    run_as_user "mkdir -p '$PI_CONFIG_DIR'"

    # models.json — registra o provider Ollama
    if [ ! -f "$PI_CONFIG_DIR/models.json" ]; then
        run_as_user "cat > '$PI_CONFIG_DIR/models.json'" <<EOF
{
  "ollama": {
    "type": "openai-compatible",
    "baseUrl": "https://${OLLAMA_HOST_INPUT}/v1",
    "models": ["qwen2.5:7b-instruct-q4_K_M"]
  }
}
EOF
        log_info "models.json criado com provider Ollama."
    else
        log_info "models.json já existe — pulando (configure manualmente se necessário)."
    fi

    # settings.json — define provider e modelo padrão
    if [ ! -f "$PI_CONFIG_DIR/settings.json" ]; then
        run_as_user "cat > '$PI_CONFIG_DIR/settings.json'" <<EOF
{
  "provider": "ollama",
  "model": "qwen2.5:7b-instruct-q4_K_M"
}
EOF
        log_info "settings.json criado com Ollama como provider padrão."
    else
        log_info "settings.json já existe — pulando."
    fi

    log_info "Pi configurado para usar: https://${OLLAMA_HOST_INPUT}"
fi

log_info "Para usar: execute 'pi' no terminal."
log_info "Documentação: https://docs.ollama.com/integrations/pi"
