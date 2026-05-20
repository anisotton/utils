#!/bin/bash

set -e

UTILS_PATH="${UTILS_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
source "$UTILS_PATH/ubuntu-setup/lib/helpers.sh"

REPORT_FILE="/tmp/system-check-$(date +%Y%m%d-%H%M%S).txt"
declare -A RESULTS
RESULTS_ORDER=()

print_header() {
    echo ""
    echo "=========================================="
    echo "  Isotton — System Check"
    echo "=========================================="
    echo ""
}

save_result() {
    local component="$1"
    local status="$2"
    local detail="$3"
    RESULTS["$component"]="$status|$detail"
    RESULTS_ORDER+=("$component")
}

print_summary() {
    echo ""
    echo "=========================================="
    echo "  Resultado Final"
    echo "=========================================="
    echo ""

    local all_ok=true

    printf "%-25s %-8s %s\n" "Componente" "Status" "Detalhe"
    printf "%-25s %-8s %s\n" "-------------------------" "--------" "-------------------------------"

    for component in "${RESULTS_ORDER[@]}"; do
        IFS='|' read -r status detail <<< "${RESULTS[$component]}"
        case "$status" in
            OK)   color="$GREEN" ;;
            WARN) color="$YELLOW"; all_ok=false ;;
            FAIL) color="$RED";   all_ok=false ;;
            *)    color="$NC"    ;;
        esac
        printf "${color}%-25s %-8s${NC} %s\n" "$component" "$status" "$detail"
    done

    echo ""
    if $all_ok; then
        log_info "Sistema OK — tudo dentro dos parâmetros esperados."
    else
        log_warning "Verifique os itens com WARN/FAIL acima."
    fi

    echo ""
    echo "Relatório salvo em: $REPORT_FILE"
}

CHECKS_PATH="$UTILS_PATH/system-check/checks"
source "$CHECKS_PATH/storage.sh"
source "$CHECKS_PATH/performance.sh"
source "$CHECKS_PATH/services.sh"
source "$CHECKS_PATH/network.sh"
source "$CHECKS_PATH/drivers.sh"

# =============================================================================
print_header

{
    echo "System Check — $(date)"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo ""
} > "$REPORT_FILE"

echo "Quais verificações deseja executar?"
echo ""
echo "  1) Todas (recomendado)"
echo "  2) Somente Armazenamento"
echo "  3) Somente Performance"
echo "  4) Somente Serviços"
echo "  5) Somente Rede e Segurança"
echo "  6) Somente Drivers"
echo "  0) Sair"
echo ""
echo "Escolha:"
read -r CHECK_CHOICE

case "$CHECK_CHOICE" in
    1)
        run_storage_check
        run_performance_check
        run_services_check
        run_network_check
        run_drivers_check
        ;;
    2) run_storage_check ;;
    3) run_performance_check ;;
    4) run_services_check ;;
    5) run_network_check ;;
    6) run_drivers_check ;;
    0)
        echo "Saindo."
        exit 0
        ;;
    *)
        log_error "Opção inválida."
        exit 1
        ;;
esac

print_summary 2>&1 | tee -a "$REPORT_FILE"
