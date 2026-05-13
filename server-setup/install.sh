#!/bin/bash

set -e

SERVER_SETUP_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SERVER_SETUP_PATH

source "$SERVER_SETUP_PATH/lib/helpers.sh"

log_info "=========================================="
log_info "  Server Setup — Configuração do Servidor"
log_info "=========================================="
log_info "Iniciando configuração..."

# 1. Core (automático)
log_info "Instalando pacotes base..."
source "$SERVER_SETUP_PATH/install/core/01-base.sh"

# 2. Network — pergunta IP
echo ""
echo -e "${GREEN}=== Configuração de Rede ===${NC}"
echo "Qual o IP estático para este servidor?"
echo "  (Enter para usar o padrão: 192.168.1.50)"
read -r NETWORK_IP_INPUT
export SERVER_IP="${NETWORK_IP_INPUT:-192.168.1.50}"
log_info "IP configurado: $SERVER_IP"

echo ""
echo "Qual o nome desta rede/servidor? (será usado como domínio: projeto.nome)"
echo "  Exemplo: 'home' → acesso via projeto.home"
echo "  (Enter para usar o padrão: server)"
read -r NETWORK_NAME_INPUT
export SERVER_NAME="${NETWORK_NAME_INPUT:-server}"
log_info "Nome configurado: $SERVER_NAME (acesso via projeto.$SERVER_NAME)"

log_info "Configurando rede..."
source "$SERVER_SETUP_PATH/install/network/01-static-ip.sh"
source "$SERVER_SETUP_PATH/install/network/02-dnsmasq.sh"

# 3. Docker + Traefik (automático)
log_info "Instalando Docker e Traefik..."
source "$SERVER_SETUP_PATH/install/docker/01-docker.sh"
source "$SERVER_SETUP_PATH/install/docker/02-traefik.sh"

# 4. Runtimes (automático)
log_info "Instalando runtimes..."
source "$SERVER_SETUP_PATH/install/runtime/01-node.sh"
source "$SERVER_SETUP_PATH/install/runtime/02-php.sh"

# 5. Browser (automático)
log_info "Instalando browser e Playwright..."
source "$SERVER_SETUP_PATH/install/browser/01-chromium.sh"
source "$SERVER_SETUP_PATH/install/browser/02-playwright.sh"

# 6. AI Tools (menu interativo)
echo ""
echo -e "${GREEN}=== Ferramentas de IA ===${NC}"
echo "Selecione quais ferramentas de IA deseja instalar:"
echo "  1) Claude Code  - CLI da Anthropic para coding"
echo "  2) Codex        - CLI da OpenAI para coding"
echo "  3) Ambos"
echo "  0) Pular"
echo ""
echo "Escolha:"
read -r AI_CHOICE

case "$AI_CHOICE" in
    1)
        source "$SERVER_SETUP_PATH/install/ai-tools/claude-code.sh"
        ;;
    2)
        source "$SERVER_SETUP_PATH/install/ai-tools/codex.sh"
        ;;
    3)
        source "$SERVER_SETUP_PATH/install/ai-tools/claude-code.sh"
        source "$SERVER_SETUP_PATH/install/ai-tools/codex.sh"
        ;;
    0|*)
        log_info "Ferramentas de IA ignoradas."
        ;;
esac

log_info "=========================================="
log_info "  Configuração do servidor concluída!"
log_info "=========================================="
log_info "IP do servidor: $SERVER_IP"
log_info "Nome da rede: $SERVER_NAME (acesso via projeto.$SERVER_NAME)"
log_info "Traefik dashboard: http://traefik.$SERVER_NAME ou http://$SERVER_IP:8080"
log_info "DNS wildcard *.$SERVER_NAME aponta para: $SERVER_IP"
log_info "IMPORTANTE: Faça logout e login novamente para o grupo docker ter efeito."
