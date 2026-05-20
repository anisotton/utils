#!/bin/bash

run_drivers_check() {
    echo ""
    echo -e "${GREEN}=== Drivers ===${NC}"
    echo ""

    ensure_packages pciutils

    # GPU
    local gpu_info
    gpu_info=$(lspci 2>/dev/null | grep -iE "vga|3d controller|display controller" || true)

    if [ -z "$gpu_info" ]; then
        log_info "Driver GPU — nenhuma GPU PCI detectada (VM?)"
    else
        local gpu_name gpu_module
        gpu_name=$(echo "$gpu_info" | head -1 | sed 's/.*: //')
        log_info "GPU detectada: $gpu_name"

        if lsmod 2>/dev/null | grep -q "^nvidia "; then
            gpu_module="nvidia"
        elif lsmod 2>/dev/null | grep -q "^amdgpu "; then
            gpu_module="amdgpu"
        elif lsmod 2>/dev/null | grep -q "^i915 "; then
            gpu_module="i915"
        else
            gpu_module=""
        fi

        if [ -n "$gpu_module" ]; then
            save_result "Driver GPU" "OK" "módulo: $gpu_module"
            log_info "Driver GPU — módulo: $gpu_module"
        else
            save_result "Driver GPU" "WARN" "nenhum módulo GPU carregado (nvidia/amdgpu/i915)"
            log_warning "Driver GPU — nenhum módulo carregado"
        fi
    fi

    # Áudio
    local audio_info
    audio_info=$(lspci 2>/dev/null | grep -iE "audio|sound|multimedia" || true)

    if [ -z "$audio_info" ]; then
        log_info "Driver Áudio — nenhum dispositivo de áudio PCI detectado"
    else
        local audio_name audio_module
        audio_name=$(echo "$audio_info" | head -1 | sed 's/.*: //')
        log_info "Áudio detectado: $audio_name"
        audio_module=$(lsmod 2>/dev/null | awk '/^snd_/ {print $1; exit}' || true)

        if [ -n "$audio_module" ]; then
            save_result "Driver Áudio" "OK" "módulo: $audio_module"
            log_info "Driver Áudio — módulo: $audio_module"
        else
            save_result "Driver Áudio" "WARN" "nenhum módulo snd_* carregado"
            log_warning "Driver Áudio — nenhum módulo snd_* detectado"
        fi
    fi

    # Rede
    local net_info
    net_info=$(lspci 2>/dev/null | grep -iE "ethernet|wireless|wi-fi|network controller" || true)

    if [ -n "$net_info" ]; then
        local net_name
        net_name=$(echo "$net_info" | head -1 | sed 's/.*: //')
        log_info "Rede detectada: $net_name"
    fi

    local active_iface
    active_iface=$(ip link show 2>/dev/null \
        | awk '/state UP/ {gsub(":",""); print $2}' \
        | grep -v "^lo$" | head -1 || true)

    if [ -n "$active_iface" ]; then
        save_result "Driver Rede" "OK" "$active_iface (link up)"
        log_info "Driver Rede — $active_iface (link up)"
    else
        save_result "Driver Rede" "WARN" "nenhuma interface com link up"
        log_warning "Driver Rede — nenhuma interface ativa"
    fi

    {
        echo "--- Drivers (lspci) ---"
        lspci 2>/dev/null || true
        echo ""
        echo "--- Módulos carregados (lsmod) ---"
        lsmod 2>/dev/null || true
        echo ""
    } >> "$REPORT_FILE"

    echo ""
}
