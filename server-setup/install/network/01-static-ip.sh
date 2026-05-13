#!/bin/bash

log_info "Configurando IP estático via netplan..."

# Detecta interface Ethernet automaticamente (exclui lo e wlan*)
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' | grep -v '^wlan' | head -1)

if [ -z "$IFACE" ]; then
    log_error "Nenhuma interface Ethernet encontrada."
    exit 1
fi

log_info "Interface detectada: $IFACE"

DEFAULT_IP="192.168.1.50"
echo ""
echo "Qual o IP estático desejado para este servidor?"
echo "  (Enter para usar o padrão: $DEFAULT_IP/24)"
read -r IP_INPUT
SERVER_IP="${IP_INPUT:-$DEFAULT_IP}"
export SERVER_IP

NETPLAN_FILE="/etc/netplan/99-server-static.yaml"
log_info "Gerando $NETPLAN_FILE..."

if [ "$EUID" -eq 0 ]; then
    cat > "$NETPLAN_FILE" <<EOF
network:
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
        addresses: [8.8.8.8, 8.8.4.4]
EOF
    netplan apply
else
    sudo tee "$NETPLAN_FILE" > /dev/null <<EOF
network:
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
        addresses: [8.8.8.8, 8.8.4.4]
EOF
    sudo netplan apply
fi

log_info "IP estático configurado: $SERVER_IP/24 na interface $IFACE"
