#!/bin/bash

set -e

trap 'echo ""; echo "Configuração falhou! Você pode tentar novamente com:"; echo "  bash -c \"\$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot-server.sh)\""; echo ""' ERR

echo ""
echo "=========================================="
echo "  Isotton — Server Setup Bootstrap"
echo "=========================================="
echo ""
echo "Este script vai clonar o repositório de utilitários"
echo "e iniciar a configuração do servidor."
echo ""
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
echo "Iniciando configuração do servidor..."
source "$UTILS_PATH/server-setup/install.sh"
