#!/bin/bash

set -e

trap 'echo ""; echo "Instalação falhou! Você pode tentar novamente com:"; echo "  bash -c \"\$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot-llm.sh)\""; echo ""' ERR

echo ""
echo "=========================================="
echo "  Isotton — LLM Local (Ollama) Bootstrap"
echo "=========================================="
echo ""
echo "Este script instala o Ollama com um modelo local."
echo "Pré-requisito: servidor já configurado com Docker e Traefik."
echo ""

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "ERRO: Docker não encontrado. Execute primeiro o boot-server.sh."
    exit 1
fi

if ! docker info &> /dev/null && ! sudo docker info &> /dev/null; then
    echo "ERRO: Docker não está rodando."
    exit 1
fi

echo "Pressione Enter para continuar (ou Ctrl+C para cancelar)..."
read -r

echo "Instalando dependências mínimas (git, curl, wget)..."
sudo apt-get update >/dev/null 2>&1
sudo apt-get install -y git curl wget >/dev/null 2>&1

UTILS_PATH="$HOME/.local/share/utils"
echo "Clonando repositório em $UTILS_PATH..."
rm -rf "$UTILS_PATH"
git clone https://github.com/anisotton/utils.git "$UTILS_PATH" >/dev/null 2>&1

if [ -n "${UTILS_REF:-}" ] && [ "$UTILS_REF" != "main" ]; then
    cd "$UTILS_PATH"
    git fetch origin "$UTILS_REF" && git checkout "$UTILS_REF"
    cd -
fi

export UTILS_PATH
SERVER_SETUP_PATH="$UTILS_PATH/server-setup"
export SERVER_SETUP_PATH

source "$SERVER_SETUP_PATH/lib/helpers.sh"

echo ""
echo "Qual o nome desta rede/servidor? (usado como domínio: ollama.nome)"
echo "  Exemplo: 'lyra' → acesso via ollama.lyra"
echo "  (Enter para usar o padrão: server)"
read -r NETWORK_NAME_INPUT
export SERVER_NAME="${NETWORK_NAME_INPUT:-server}"

echo ""
source "$SERVER_SETUP_PATH/install/llm/install.sh"
