#!/bin/bash

set -e

UTILS_PATH="${UTILS_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export UTILS_PATH

echo ""
echo "=========================================="
echo "  Isotton — Utils"
echo "=========================================="
echo ""
echo "Módulos disponíveis:"
echo "  1) Ubuntu Dev Setup  - Ambiente de desenvolvimento completo para Ubuntu"
echo "  2) Server Setup      - Configuração de servidor Linux (Docker, Traefik, dnsmasq, IA)"
echo "  3) Hardware Check    - Verificação de integridade de hardware (RAM, SSD, CPU, temperatura)"
echo ""
echo "Escolha o módulo a instalar (ou 0 para sair):"
read -r MODULE_CHOICE

case "$MODULE_CHOICE" in
    1)
        source "$UTILS_PATH/ubuntu-setup/install.sh"
        ;;
    2)
        source "$UTILS_PATH/server-setup/install.sh"
        ;;
    3)
        source "$UTILS_PATH/hardware-check.sh"
        ;;
    0)
        echo "Saindo."
        exit 0
        ;;
    *)
        echo "Opção inválida: $MODULE_CHOICE"
        exit 1
        ;;
esac
