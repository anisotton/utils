#!/bin/bash

log_info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    log_warning "Docker não encontrado. Instalando Docker CE..."
    ensure_packages ca-certificates curl gnupg lsb-release

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    if [ "$EUID" -eq 0 ]; then
        apt-get update
    else
        sudo apt-get update
    fi
    apt_install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    log_info "Docker instalado: $(docker --version)"
else
    log_info "Docker já instalado: $(docker --version)"
fi

log_info "Adicionando $REAL_USER ao grupo docker..."
if ! groups "$REAL_USER" | grep -q docker; then
    if [ "$EUID" -eq 0 ]; then
        usermod -aG docker "$REAL_USER"
    else
        sudo usermod -aG docker "$REAL_USER"
    fi
    log_info "Usuário $REAL_USER adicionado ao grupo docker (requer logout para ter efeito)"
else
    log_info "Usuário $REAL_USER já está no grupo docker"
fi

if [ "$EUID" -eq 0 ]; then
    systemctl enable docker
    systemctl start docker
else
    sudo systemctl enable docker
    sudo systemctl start docker
fi
