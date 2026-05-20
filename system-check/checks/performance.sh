#!/bin/bash

run_performance_check() {
    echo ""
    echo -e "${GREEN}=== Performance ===${NC}"
    echo ""

    # Load average
    local load1 ncpus
    load1=$(awk '{print $1}' /proc/loadavg)
    ncpus=$(nproc)

    local load_warn load_fail
    load_warn=$(awk -v l="$load1" -v c="$ncpus" 'BEGIN{print (l > c) ? "yes" : "no"}')
    load_fail=$(awk -v l="$load1" -v c="$ncpus" 'BEGIN{print (l > c*2) ? "yes" : "no"}')

    if [ "$load_fail" = "yes" ]; then
        save_result "Load Average" "FAIL" "$load1 (${ncpus} CPUs)"
        log_error "Load Average — $load1 com ${ncpus} CPUs"
    elif [ "$load_warn" = "yes" ]; then
        save_result "Load Average" "WARN" "$load1 (${ncpus} CPUs)"
        log_warning "Load Average — $load1 com ${ncpus} CPUs"
    else
        save_result "Load Average" "OK" "$load1 (${ncpus} CPUs)"
        log_info "Load Average — $load1 (${ncpus} CPUs)"
    fi

    # RAM
    local total_kb available_kb free_pct total_h available_h
    total_kb=$(awk '/^MemTotal:/    {print $2}' /proc/meminfo)
    available_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    free_pct=$(awk -v a="$available_kb" -v t="$total_kb" 'BEGIN{printf "%d", (a/t)*100}')
    total_h=$(awk -v k="$total_kb"         'BEGIN{printf "%.1fG", k/1024/1024}')
    available_h=$(awk -v k="$available_kb" 'BEGIN{printf "%.1fG", k/1024/1024}')

    if [ "$free_pct" -le 5 ]; then
        save_result "RAM" "FAIL" "livre: ${available_h}/${total_h} (${free_pct}%)"
        log_error "RAM — livre: ${available_h}/${total_h} (${free_pct}%)"
    elif [ "$free_pct" -le 15 ]; then
        save_result "RAM" "WARN" "livre: ${available_h}/${total_h} (${free_pct}%)"
        log_warning "RAM — livre: ${available_h}/${total_h} (${free_pct}%)"
    else
        save_result "RAM" "OK" "livre: ${available_h}/${total_h} (${free_pct}%)"
        log_info "RAM — livre: ${available_h}/${total_h} (${free_pct}%)"
    fi

    # Swap
    local swap_total_kb swap_free_kb
    swap_total_kb=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
    swap_free_kb=$(awk '/^SwapFree:/  {print $2}' /proc/meminfo)

    if [ "$swap_total_kb" -eq 0 ]; then
        save_result "Swap" "OK" "sem swap configurado"
        log_info "Swap — sem swap configurado"
    else
        local swap_used_kb swap_pct swap_used_h swap_total_h
        swap_used_kb=$((swap_total_kb - swap_free_kb))
        swap_pct=$((swap_used_kb * 100 / swap_total_kb))
        swap_used_h=$(awk -v k="$swap_used_kb"   'BEGIN{printf "%.1fG", k/1024/1024}')
        swap_total_h=$(awk -v k="$swap_total_kb" 'BEGIN{printf "%.1fG", k/1024/1024}')

        if [ "$swap_pct" -ge 90 ]; then
            save_result "Swap" "FAIL" "${swap_pct}% usado (${swap_used_h}/${swap_total_h})"
            log_error "Swap — ${swap_pct}% usado"
        elif [ "$swap_pct" -ge 50 ]; then
            save_result "Swap" "WARN" "${swap_pct}% usado (${swap_used_h}/${swap_total_h})"
            log_warning "Swap — ${swap_pct}% usado"
        else
            save_result "Swap" "OK" "${swap_pct}% usado (${swap_used_h}/${swap_total_h})"
            log_info "Swap — ${swap_pct}% usado (${swap_used_h}/${swap_total_h})"
        fi
    fi

    echo ""
    echo "Top 5 processos por CPU:"
    ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 && NR<=6 {printf "  %-12s %5s%%  %s\n", $1, $3, $11}'
    echo ""
    echo "Top 5 processos por RAM:"
    ps aux --sort=-%mem 2>/dev/null | awk 'NR>1 && NR<=6 {printf "  %-12s %5s%%  %s\n", $1, $4, $11}'
    echo ""

    {
        echo "--- Performance ---"
        echo "Load: $(cat /proc/loadavg)"
        free -h
        echo ""
    } >> "$REPORT_FILE"
}
