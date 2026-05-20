#!/bin/bash

run_services_check() {
    echo ""
    echo -e "${GREEN}=== Serviços Críticos ===${NC}"
    echo ""

    local CRITICAL_SERVICES=("docker" "ssh" "traefik" "nginx" "apache2" "ufw" "fail2ban" "cron")

    for svc in "${CRITICAL_SERVICES[@]}"; do
        if systemctl list-unit-files "${svc}.service" 2>/dev/null | grep -q "${svc}"; then
            local status
            status=$(systemctl is-active "$svc" 2>/dev/null || true)
            case "$status" in
                active)
                    save_result "$svc" "OK" "ativo"
                    log_info "$svc — ativo"
                    ;;
                failed)
                    save_result "$svc" "FAIL" "falhou (execute: systemctl status $svc)"
                    log_error "$svc — status: failed"
                    ;;
                *)
                    save_result "$svc" "WARN" "inativo ($status)"
                    log_warning "$svc — inativo ($status)"
                    ;;
            esac
        else
            log_info "$svc — não instalado (ignorado)"
        fi
    done

    {
        echo "--- Serviços com falha ---"
        systemctl list-units --type=service --state=failed 2>/dev/null || true
        echo ""
    } >> "$REPORT_FILE"

    echo ""
}
