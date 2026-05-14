#!/bin/bash

set -e

UTILS_PATH="${UTILS_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
source "$UTILS_PATH/ubuntu-setup/lib/helpers.sh"

REPORT_FILE="/tmp/hardware-check-$(date +%Y%m%d-%H%M%S).txt"
declare -A RESULTS

# =============================================================================
print_header() {
    echo ""
    echo "=========================================="
    echo "  Isotton — Hardware Check"
    echo "=========================================="
    echo ""
}

save_result() {
    local component="$1"
    local status="$2"   # OK | WARN | FAIL
    local detail="$3"
    RESULTS["$component"]="$status|$detail"
}

print_summary() {
    echo ""
    echo "=========================================="
    echo "  Resultado Final"
    echo "=========================================="
    echo ""

    local all_ok=true

    printf "%-20s %-8s %s\n" "Componente" "Status" "Detalhe"
    printf "%-20s %-8s %s\n" "--------------------" "--------" "-------------------------------"

    for component in "RAM (memtest)" "SSD" "CPU/Stress" "Temperatura"; do
        if [[ -v "RESULTS[$component]" ]]; then
            IFS='|' read -r status detail <<< "${RESULTS[$component]}"
            case "$status" in
                OK)   color="$GREEN" ;;
                WARN) color="$YELLOW"; all_ok=false ;;
                FAIL) color="$RED";   all_ok=false ;;
            esac
            printf "${color}%-20s %-8s${NC} %s\n" "$component" "$status" "$detail"
        else
            printf "${YELLOW}%-20s %-8s${NC} %s\n" "$component" "SKIP" "não executado"
        fi
    done

    echo ""
    if $all_ok; then
        log_info "Hardware OK — pode prosseguir com a configuração do servidor."
    else
        log_warning "Verifique os itens com WARN/FAIL antes de colocar o servidor em produção."
    fi

    echo ""
    echo "Relatório salvo em: $REPORT_FILE"
}

# =============================================================================
# MEMTEST86+
# =============================================================================
run_memtest_info() {
    echo ""
    echo -e "${GREEN}=== RAM — memtest86+ ===${NC}"
    echo ""
    echo "O memtest86+ roda fora do sistema operacional (via GRUB)."
    echo "Não é possível executá-lo de dentro do Linux."
    echo ""

    ensure_packages memtest86+
    log_info "memtest86+ instalado."

    echo ""
    echo "Como rodar:"
    echo "  1. Reinicie o servidor"
    echo "  2. No menu do GRUB, selecione 'Memory test (memtest86+)'"
    echo "  3. Aguarde pelo menos 1 passagem completa (~30-60 min)"
    echo "  4. Sem erros = RAM OK"
    echo ""

    echo "Memtest instalado — rode manualmente via GRUB após reinicialização." >> "$REPORT_FILE"
    save_result "RAM (memtest)" "WARN" "requer reboot para executar via GRUB"
}

# =============================================================================
# SMARTCTL — SSD/NVMe
# =============================================================================
run_storage_check() {
    echo ""
    echo -e "${GREEN}=== Storage — smartctl ===${NC}"
    echo ""

    ensure_packages smartmontools

    local disks
    disks=$(lsblk -d -o NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}')

    if [ -z "$disks" ]; then
        log_warning "Nenhum disco encontrado."
        save_result "SSD" "WARN" "nenhum disco detectado"
        return
    fi

    local disk_status="OK"
    local disk_detail=""

    for disk in $disks; do
        echo "Verificando $disk..."
        echo "--- $disk ---" >> "$REPORT_FILE"

        # Health geral
        local health_output
        health_output=$(sudo smartctl -H "$disk" 2>&1 || true)
        echo "$health_output" >> "$REPORT_FILE"

        if echo "$health_output" | grep -q "PASSED\|OK\|ok"; then
            log_info "$disk — saúde: OK"
            disk_detail+="$disk:OK "
        elif echo "$health_output" | grep -qi "failed\|FAILED"; then
            log_error "$disk — FALHOU no teste de saúde!"
            disk_detail+="$disk:FAIL "
            disk_status="FAIL"
        else
            log_warning "$disk — resultado inconclusivo (pode ser NVMe sem suporte SMART completo)"
            disk_detail+="$disk:WARN "
            [ "$disk_status" = "OK" ] && disk_status="WARN"
        fi

        # Atributos resumidos
        echo "Atributos SMART de $disk:" >> "$REPORT_FILE"
        sudo smartctl -A "$disk" >> "$REPORT_FILE" 2>&1 || true

        echo ""
    done

    save_result "SSD" "$disk_status" "${disk_detail%% }"
}

# =============================================================================
# STRESS-NG — CPU + RAM sob carga
# =============================================================================
run_stress_test() {
    echo ""
    echo -e "${GREEN}=== CPU/RAM — stress-ng (5 minutos) ===${NC}"
    echo ""

    ensure_packages stress-ng

    local cpu_cores
    cpu_cores=$(nproc)
    log_info "Rodando stress em $cpu_cores CPUs + 2 workers de memória por 5 minutos..."
    echo ""

    echo "--- stress-ng ---" >> "$REPORT_FILE"

    local stress_output
    if stress_output=$(sudo stress-ng --cpu "$cpu_cores" --vm 2 --vm-bytes 256M \
        --timeout 300s --metrics --log-file /tmp/stress-ng.log 2>&1); then
        echo "$stress_output" >> "$REPORT_FILE"
        cat /tmp/stress-ng.log >> "$REPORT_FILE" 2>/dev/null || true
        log_info "Stress test concluído sem erros."
        save_result "CPU/Stress" "OK" "${cpu_cores} cores + 2 vm workers, 5 min"
    else
        log_error "Stress test falhou ou reportou erros!"
        echo "$stress_output" >> "$REPORT_FILE"
        cat /tmp/stress-ng.log >> "$REPORT_FILE" 2>/dev/null || true
        save_result "CPU/Stress" "FAIL" "erros durante stress test"
    fi
}

# =============================================================================
# LM-SENSORS — temperatura
# =============================================================================
run_temp_check() {
    echo ""
    echo -e "${GREEN}=== Temperatura — lm-sensors ===${NC}"
    echo ""

    ensure_packages lm-sensors

    sudo sensors-detect --auto >/dev/null 2>&1 || true

    local sensors_output
    sensors_output=$(sensors 2>&1 || true)

    if [ -z "$sensors_output" ] || echo "$sensors_output" | grep -qi "no sensors\|not found"; then
        log_warning "Nenhum sensor de temperatura detectado."
        save_result "Temperatura" "WARN" "nenhum sensor detectado"
        return
    fi

    echo "$sensors_output"
    echo ""
    echo "--- lm-sensors ---" >> "$REPORT_FILE"
    echo "$sensors_output" >> "$REPORT_FILE"

    # Extrai apenas as leituras correntes (logo após o ":"), ignorando thresholds
    # como "high = +80.0°C, crit = +95.0°C".
    local current_temps
    current_temps=$(echo "$sensors_output" | grep -oP ':\s+\+?\K[0-9]+\.[0-9]+(?=°C)' || true)

    if [ -z "$current_temps" ]; then
        log_warning "Nenhuma leitura de temperatura encontrada na saída do sensors."
        save_result "Temperatura" "WARN" "sem leituras de temperatura"
        return
    fi

    # Verifica temperaturas críticas (>85°C)
    local critical
    critical=$(echo "$current_temps" | awk '$1 > 85 {printf "%s ", $1}' | sed 's/ $//')

    if [ -n "$critical" ]; then
        log_error "Temperatura crítica detectada: ${critical}°C"
        save_result "Temperatura" "FAIL" "acima de 85°C: ${critical}°C"
    else
        local max_temp
        max_temp=$(echo "$current_temps" | sort -n | tail -1)
        log_info "Temperatura normal. Máxima lida: ${max_temp}°C"
        save_result "Temperatura" "OK" "máx: ${max_temp}°C (abaixo de 85°C)"
    fi
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================
print_header

{
    echo "Hardware Check — $(date)"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo ""
} > "$REPORT_FILE"

echo "Quais verificações deseja executar?"
echo ""
echo "  1) Todas (recomendado)"
echo "  2) Somente Storage (smartctl)"
echo "  3) Somente CPU/Stress (stress-ng)"
echo "  4) Somente Temperatura (lm-sensors)"
echo "  5) Informações do memtest86+"
echo "  0) Sair"
echo ""
echo "Escolha:"
read -r CHECK_CHOICE

case "$CHECK_CHOICE" in
    1)
        run_memtest_info
        run_storage_check
        run_stress_test
        run_temp_check
        ;;
    2)
        run_storage_check
        ;;
    3)
        run_stress_test
        ;;
    4)
        run_temp_check
        ;;
    5)
        run_memtest_info
        ;;
    0)
        echo "Saindo."
        exit 0
        ;;
    *)
        log_error "Opção inválida."
        exit 1
        ;;
esac

print_summary
