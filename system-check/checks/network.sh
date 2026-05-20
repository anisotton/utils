#!/bin/bash

run_network_check() {
    echo ""
    echo -e "${GREEN}=== Rede e Segurança ===${NC}"
    echo ""

    # Conectividade
    if ping -c 3 -W 3 8.8.8.8 &>/dev/null; then
        save_result "Internet" "OK" "8.8.8.8 acessível"
        log_info "Internet — acessível"
    else
        save_result "Internet" "FAIL" "sem resposta de 8.8.8.8"
        log_error "Internet — sem conectividade"
    fi

    # Portas abertas (informativo)
    echo ""
    echo "Portas TCP em escuta:"
    ss -tlnp 2>/dev/null | awk 'NR>1 {printf "  %-25s %s\n", $4, $6}' | sort -u
    echo ""

    # SSH config
    local sshd_config="/etc/ssh/sshd_config"
    if [ -f "$sshd_config" ]; then
        local root_login
        root_login=$(grep -iE "^PermitRootLogin" "$sshd_config" 2>/dev/null \
            | awk '{print $2}' | head -1)
        root_login="${root_login:-prohibit-password}"

        if echo "$root_login" | grep -qi "^yes$"; then
            save_result "SSH PermitRootLogin" "WARN" "yes — risco de segurança"
            log_warning "SSH — PermitRootLogin yes"
        else
            save_result "SSH PermitRootLogin" "OK" "$root_login"
            log_info "SSH — PermitRootLogin: $root_login"
        fi

        local ssh_port
        ssh_port=$(grep -iE "^Port " "$sshd_config" 2>/dev/null \
            | awk '{print $2}' | head -1)
        ssh_port="${ssh_port:-22}"

        if [ "$ssh_port" = "22" ]; then
            save_result "SSH Porta" "WARN" "porta padrão 22"
            log_warning "SSH — usando porta padrão 22"
        else
            save_result "SSH Porta" "OK" "porta $ssh_port"
            log_info "SSH — porta $ssh_port"
        fi
    else
        save_result "SSH Config" "OK" "sshd não instalado"
        log_info "SSH — sshd não instalado"
    fi

    # Updates pendentes
    echo ""
    log_info "Verificando updates pendentes..."
    local updates_count
    updates_count=$(apt list --upgradable 2>/dev/null | awk '/upgradable/{c++} END{print c+0}')

    if [ "$updates_count" -gt 20 ]; then
        save_result "Updates Pendentes" "FAIL" "$updates_count pacotes disponíveis"
        log_error "Updates — $updates_count pacotes pendentes"
    elif [ "$updates_count" -gt 0 ]; then
        save_result "Updates Pendentes" "WARN" "$updates_count pacotes disponíveis"
        log_warning "Updates — $updates_count pacotes pendentes"
    else
        save_result "Updates Pendentes" "OK" "sistema atualizado"
        log_info "Updates — sistema atualizado"
    fi

    {
        echo "--- Rede ---"
        ip addr show 2>/dev/null || true
        echo ""
        echo "--- SSH Config ---"
        grep -vE "^#|^$" "$sshd_config" 2>/dev/null || echo "não encontrado"
        echo ""
    } >> "$REPORT_FILE"

    echo ""
}
