#!/bin/bash

log_info "Configurando dnsmasq..."

# Usa o IP e nome definidos no orquestrador, ou detecta valores padrão
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
    log_warning "SERVER_IP não definido, usando IP detectado: $SERVER_IP"
fi

if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME="server"
    log_warning "SERVER_NAME não definido, usando padrão: $SERVER_NAME"
fi

ensure_packages dnsmasq

# Desabilita systemd-resolved se ativo (conflito na porta 53)
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
    log_warning "systemd-resolved está ativo. Desabilitando para evitar conflito na porta 53..."
    if [ "$EUID" -eq 0 ]; then
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
        rm -f /etc/resolv.conf
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
    else
        sudo systemctl stop systemd-resolved
        sudo systemctl disable systemd-resolved
        sudo rm -f /etc/resolv.conf
        echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
    fi
    log_info "systemd-resolved desabilitado"
fi

DNSMASQ_CONF="/etc/dnsmasq.conf"
log_info "Configurando $DNSMASQ_CONF..."

if [ "$EUID" -eq 0 ]; then
    cat > "$DNSMASQ_CONF" <<EOF
# Resolve *.$SERVER_NAME para o IP do servidor
address=/.$SERVER_NAME/$SERVER_IP

# DNS externo
server=8.8.8.8
server=8.8.4.4

# Escuta no localhost e no IP do servidor
listen-address=127.0.0.1,$SERVER_IP

# Não redireciona consultas de hosts sem domínio
domain-needed
bogus-priv
EOF
    systemctl restart dnsmasq
    systemctl enable dnsmasq
else
    sudo tee "$DNSMASQ_CONF" > /dev/null <<EOF
# Resolve *.$SERVER_NAME para o IP do servidor
address=/.$SERVER_NAME/$SERVER_IP

# DNS externo
server=8.8.8.8
server=8.8.4.4

# Escuta no localhost e no IP do servidor
listen-address=127.0.0.1,$SERVER_IP

# Não redireciona consultas de hosts sem domínio
domain-needed
bogus-priv
EOF
    sudo systemctl restart dnsmasq
    sudo systemctl enable dnsmasq
fi

log_info "dnsmasq configurado. Domínios *.$SERVER_NAME apontam para $SERVER_IP"
