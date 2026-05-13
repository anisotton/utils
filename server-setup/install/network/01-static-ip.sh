#!/bin/bash

log_info "Configurando IP estático via netplan..."

# Detecta interface Ethernet automaticamente (exclui lo e wlan*)
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' | grep -v '^wlan' | head -1)

if [ -z "$IFACE" ]; then
    log_error "Nenhuma interface Ethernet encontrada."
    exit 1
fi

log_info "Interface detectada: $IFACE"

# SERVER_IP já coletado em install.sh; usa fallback só se não estiver definido
if [ -z "${SERVER_IP:-}" ]; then
    echo ""
    echo "Qual o IP estático desejado para este servidor?"
    echo "  (Enter para usar o padrão: 192.168.1.50)"
    read -r IP_INPUT
    SERVER_IP="${IP_INPUT:-192.168.1.50}"
    export SERVER_IP
fi

NETPLAN_FILE="/etc/netplan/99-server-static.yaml"

# Verifica se o IP já está configurado corretamente — evita derrubar SSH em reexecução
CURRENT_IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [ "$CURRENT_IP" = "$SERVER_IP" ] && [ -f "$NETPLAN_FILE" ]; then
    log_info "IP estático já configurado: $SERVER_IP — pulando."
    return 0 2>/dev/null || exit 0
fi

log_info "Gerando $NETPLAN_FILE..."

echo ""
echo -e "${YELLOW}=========================================="
echo "  ATENÇÃO — A conexão SSH vai cair!"
echo "=========================================="
echo ""
echo "  Ao aplicar o novo IP, a interface de rede"
echo "  será reconfigurada e esta sessão SSH será"
echo "  encerrada imediatamente."
echo ""
echo "  Após a queda, reconecte via:"
echo "    ssh $(whoami)@${SERVER_IP}"
echo ""
echo "  O script continuará automaticamente na"
echo "  próxima vez que você rodar o setup."
echo -e "==========================================${NC}"
echo ""
echo "Pressione Enter para continuar (ou Ctrl+C para cancelar)..."
read -r

NETPLAN_CONTENT="network:
  version: 2
  ethernets:
    $IFACE:
      dhcp4: false
      addresses:
        - $SERVER_IP/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]"

if [ "$EUID" -eq 0 ]; then
    echo "$NETPLAN_CONTENT" > "$NETPLAN_FILE"
    chmod 600 "$NETPLAN_FILE"
    netplan apply
else
    echo "$NETPLAN_CONTENT" | sudo tee "$NETPLAN_FILE" > /dev/null
    sudo chmod 600 "$NETPLAN_FILE"
    sudo netplan apply
fi

log_info "IP estático configurado: $SERVER_IP/24 na interface $IFACE"
