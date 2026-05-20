# System Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar o módulo `system-check.sh` — 4º opção no menu principal — que verifica a saúde do SO em operação e exibe uma tabela colorida com status OK/WARN/FAIL por item.

**Architecture:** Orquestrador (`system-check.sh`) que declara helpers compartilhados e faz `source` de 5 arquivos de verificação em `system-check/checks/`. Segue exatamente o padrão de `hardware-check.sh`: `declare -A RESULTS`, `save_result`, `print_summary` com tabela colorida ao final. Um array `RESULTS_ORDER` preserva a ordem de inserção para a tabela final (bash associativo não garante ordem).

**Tech Stack:** Bash 5+, ferramentas padrão Ubuntu 22.04+ — `df`, `ps`, `awk`, `ping`, `ss`, `lspci`, `lsmod`, `systemctl`, `ip`, `apt`

---

## Mapa de arquivos

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `system-check.sh` | Criar | Orquestrador: header, menu, source checks, print_summary |
| `system-check/checks/storage.sh` | Criar | Uso de disco, inodes, top dirs |
| `system-check/checks/performance.sh` | Criar | CPU load, RAM, swap, top processos |
| `system-check/checks/services.sh` | Criar | Status de serviços systemd críticos |
| `system-check/checks/network.sh` | Criar | Conectividade, portas, SSH config, updates |
| `system-check/checks/drivers.sh` | Criar | Drivers GPU, áudio e rede via lspci + lsmod |
| `install.sh` | Modificar | Adicionar opção 4) System Check no menu |

---

## Task 1: Scaffold — orquestrador e estrutura de diretórios

**Files:**
- Create: `system-check.sh`
- Create: `system-check/checks/.gitkeep`
- Modify: `install.sh`

- [ ] **Step 1: Criar o diretório de checks**

```bash
mkdir -p system-check/checks
```

- [ ] **Step 2: Criar `system-check.sh`**

```bash
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
```

- [ ] **Step 3: Criar stubs temporários dos checks (necessários para `source` não falhar)**

Crie `system-check/checks/storage.sh` com conteúdo mínimo:
```bash
#!/bin/bash
run_storage_check() { log_info "storage check — stub"; }
```

Repita para `performance.sh`, `services.sh`, `network.sh`, `drivers.sh` — troque o nome da função em cada um:
```bash
run_performance_check() { log_info "performance check — stub"; }
run_services_check()    { log_info "services check — stub"; }
run_network_check()     { log_info "network check — stub"; }
run_drivers_check()     { log_info "drivers check — stub"; }
```

- [ ] **Step 4: Adicionar opção 4 em `install.sh`**

Localize o bloco de menu em `install.sh` e substitua:
```bash
echo "Módulos disponíveis:"
echo "  1) Ubuntu Dev Setup  - Ambiente de desenvolvimento completo para Ubuntu"
echo "  2) Server Setup      - Configuração de servidor Linux (Docker, Traefik, dnsmasq, IA)"
echo "  3) Hardware Check    - Verificação de integridade de hardware (RAM, SSD, CPU, temperatura)"
echo ""
echo "Escolha o módulo a instalar (ou 0 para sair):"
```

Por:
```bash
echo "Módulos disponíveis:"
echo "  1) Ubuntu Dev Setup  - Ambiente de desenvolvimento completo para Ubuntu"
echo "  2) Server Setup      - Configuração de servidor Linux (Docker, Traefik, dnsmasq, IA)"
echo "  3) Hardware Check    - Verificação de integridade de hardware (RAM, SSD, CPU, temperatura)"
echo "  4) System Check      - Verificação de saúde do SO (disco, serviços, rede, drivers)"
echo ""
echo "Escolha o módulo a instalar (ou 0 para sair):"
```

E no `case`:
```bash
    3)
        source "$UTILS_PATH/hardware-check.sh"
        ;;
    4)
        source "$UTILS_PATH/system-check.sh"
        ;;
```

- [ ] **Step 5: Verificar que o scaffold funciona (escolha opção "1" e confirme que os stubs rodam)**

```bash
bash install.sh
# escolha 4, depois 1
```

Saída esperada: header "Isotton — System Check", cinco linhas de `[INFO]` dos stubs, tabela vazia com "Sistema OK".

- [ ] **Step 6: Commit**

```bash
git add system-check.sh system-check/checks/ install.sh
git commit -m "feat: adiciona scaffold do módulo system-check"
```

---

## Task 2: storage.sh — verificação de armazenamento

**Files:**
- Modify: `system-check/checks/storage.sh`

- [ ] **Step 1: Substituir o stub pelo conteúdo real**

```bash
#!/bin/bash

run_storage_check() {
    echo ""
    echo -e "${GREEN}=== Armazenamento ===${NC}"
    echo ""

    local partitions
    partitions=$(df -h --output=target,pcent,used,size,fstype 2>/dev/null \
        | awk 'NR>1 && ($5=="ext4" || $5=="xfs" || $5=="btrfs" || $5=="vfat") {print}')

    if [ -z "$partitions" ]; then
        log_warning "Nenhuma partição relevante encontrada."
        save_result "Disco" "WARN" "nenhuma partição detectada"
    else
        while IFS= read -r line; do
            local mountpoint pct_str pct used size
            mountpoint=$(echo "$line" | awk '{print $1}')
            pct_str=$(echo "$line"    | awk '{print $2}')
            pct="${pct_str//%/}"
            used=$(echo "$line"       | awk '{print $3}')
            size=$(echo "$line"       | awk '{print $4}')

            if [ "$pct" -ge 95 ]; then
                save_result "Disco $mountpoint" "FAIL" "${pct}% usado (${used}/${size})"
                log_error "Disco $mountpoint — ${pct}% usado"
            elif [ "$pct" -ge 85 ]; then
                save_result "Disco $mountpoint" "WARN" "${pct}% usado (${used}/${size})"
                log_warning "Disco $mountpoint — ${pct}% usado"
            else
                save_result "Disco $mountpoint" "OK" "${pct}% usado (${used}/${size})"
                log_info "Disco $mountpoint — ${pct}% usado (${used}/${size})"
            fi
        done <<< "$partitions"
    fi

    local inode_partitions
    inode_partitions=$(df -i --output=target,ipcent,fstype 2>/dev/null \
        | awk 'NR>1 && ($3=="ext4" || $3=="xfs" || $3=="btrfs") && $2!="-" {print}')

    while IFS= read -r line; do
        local mountpoint ipcent_str ipcent
        mountpoint=$(echo "$line"  | awk '{print $1}')
        ipcent_str=$(echo "$line"  | awk '{print $2}')
        ipcent="${ipcent_str//%/}"

        if [ "$ipcent" -ge 85 ]; then
            save_result "Inodes $mountpoint" "WARN" "${ipcent}% usado"
            log_warning "Inodes $mountpoint — ${ipcent}% usado"
        else
            save_result "Inodes $mountpoint" "OK" "${ipcent}% usado"
            log_info "Inodes $mountpoint — ${ipcent}% usado (${ipcent}%)"
        fi
    done <<< "$inode_partitions"

    echo ""
    echo "Top 5 maiores diretórios em /:"
    du -sh --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/run \
        /*/  2>/dev/null \
        | sort -rh | head -5 \
        | while read -r sz dir; do printf "  %-8s %s\n" "$sz" "$dir"; done
    echo ""

    {
        echo "--- Armazenamento (df -h) ---"
        df -h 2>/dev/null
        echo ""
    } >> "$REPORT_FILE"
}
```

- [ ] **Step 2: Rodar e verificar saída**

```bash
bash system-check.sh
# escolha 2 (Somente Armazenamento)
```

Saída esperada: linhas `[INFO]` ou `[WARNING]` para cada partição montada (ex: `/`, `/home`), lista de inodes, top 5 diretórios, tabela final com entradas `Disco /` e `Inodes /`.

- [ ] **Step 3: Commit**

```bash
git add system-check/checks/storage.sh
git commit -m "feat: implementa verificação de armazenamento no system-check"
```

---

## Task 3: performance.sh — CPU, RAM, swap e processos

**Files:**
- Modify: `system-check/checks/performance.sh`

- [ ] **Step 1: Substituir o stub pelo conteúdo real**

```bash
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
    total_h=$(awk -v k="$total_kb"     'BEGIN{printf "%.1fG", k/1024/1024}')
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

    # Top processos (informativo)
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
```

- [ ] **Step 2: Rodar e verificar saída**

```bash
bash system-check.sh
# escolha 3 (Somente Performance)
```

Saída esperada: `[INFO]` de Load Average, RAM e Swap com valores reais da máquina, seguido de dois blocos "Top 5 processos". Tabela final mostra `Load Average`, `RAM`, `Swap`.

- [ ] **Step 3: Commit**

```bash
git add system-check/checks/performance.sh
git commit -m "feat: implementa verificação de performance no system-check"
```

---

## Task 4: services.sh — status de serviços systemd críticos

**Files:**
- Modify: `system-check/checks/services.sh`

- [ ] **Step 1: Substituir o stub pelo conteúdo real**

```bash
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
                    save_result "$svc" "FAIL" "falhou (systemctl status $svc para detalhes)"
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
        echo "--- Serviços ---"
        systemctl list-units --type=service --state=failed 2>/dev/null || true
        echo ""
    } >> "$REPORT_FILE"

    echo ""
}
```

- [ ] **Step 2: Rodar e verificar saída**

```bash
bash system-check.sh
# escolha 4 (Somente Serviços)
```

Saída esperada: para cada serviço instalado na máquina (`docker`, `ssh`, etc.) aparece uma linha `[INFO]` ou `[WARNING]`. Serviços não instalados aparecem como `[INFO] ... não instalado (ignorado)`. Tabela final lista apenas os instalados.

- [ ] **Step 3: Commit**

```bash
git add system-check/checks/services.sh
git commit -m "feat: implementa verificação de serviços no system-check"
```

---

## Task 5: network.sh — rede, segurança SSH e updates

**Files:**
- Modify: `system-check/checks/network.sh`

- [ ] **Step 1: Substituir o stub pelo conteúdo real**

```bash
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
            | awk '{print $2}' | head -1 || echo "não definido")

        if echo "$root_login" | grep -qi "^yes$"; then
            save_result "SSH PermitRootLogin" "WARN" "yes — risco de segurança"
            log_warning "SSH — PermitRootLogin yes"
        else
            save_result "SSH PermitRootLogin" "OK" "$root_login"
            log_info "SSH — PermitRootLogin: $root_login"
        fi

        local ssh_port
        ssh_port=$(grep -iE "^Port " "$sshd_config" 2>/dev/null \
            | awk '{print $2}' | head -1 || echo "22")
        ssh_port="${ssh_port:-22}"

        if [ "$ssh_port" = "22" ]; then
            save_result "SSH Porta" "WARN" "porta padrão 22"
            log_warning "SSH — usando porta padrão 22"
        else
            save_result "SSH Porta" "OK" "porta $ssh_port"
            log_info "SSH — porta $ssh_port"
        fi
    else
        save_result "SSH Config" "OK" "sshd não configurado"
        log_info "SSH — sshd não instalado"
    fi

    # Updates pendentes
    echo ""
    log_info "Verificando updates pendentes..."
    local updates_count
    updates_count=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")

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
```

- [ ] **Step 2: Rodar e verificar saída**

```bash
bash system-check.sh
# escolha 5 (Somente Rede e Segurança)
```

Saída esperada: `[INFO] Internet — acessível`, lista de portas TCP, resultado de SSH config, resultado de updates. Tabela final mostra `Internet`, `SSH PermitRootLogin`, `SSH Porta`, `Updates Pendentes`.

- [ ] **Step 3: Commit**

```bash
git add system-check/checks/network.sh
git commit -m "feat: implementa verificação de rede e segurança no system-check"
```

---

## Task 6: drivers.sh — GPU, áudio e rede via lspci + lsmod

**Files:**
- Modify: `system-check/checks/drivers.sh`

- [ ] **Step 1: Substituir o stub pelo conteúdo real**

```bash
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
```

- [ ] **Step 2: Rodar e verificar saída**

```bash
bash system-check.sh
# escolha 6 (Somente Drivers)
```

Saída esperada: para cada categoria (GPU, Áudio, Rede) aparece uma linha `[INFO]` com o hardware detectado e o módulo carregado. Tabela final mostra `Driver GPU`, `Driver Áudio`, `Driver Rede`.

- [ ] **Step 3: Commit**

```bash
git add system-check/checks/drivers.sh
git commit -m "feat: implementa verificação de drivers no system-check"
```

---

## Task 7: Teste de integração completo

**Files:** Nenhum novo — validação end-to-end.

- [ ] **Step 1: Rodar todas as verificações juntas**

```bash
bash system-check.sh
# escolha 1 (Todas)
```

Saída esperada: header "Isotton — System Check", todas as 5 seções executando em sequência, tabela final com todas as entradas (Disco /, Inodes /, Load Average, RAM, Swap, serviços instalados, Internet, SSH PermitRootLogin, SSH Porta, Updates Pendentes, Driver GPU, Driver Áudio, Driver Rede). Linha "Relatório salvo em: /tmp/system-check-*.txt".

- [ ] **Step 2: Verificar que o relatório foi salvo**

```bash
cat /tmp/system-check-*.txt | head -40
```

Saída esperada: cabeçalho com hostname/kernel, seções de armazenamento, performance, serviços, rede e drivers.

- [ ] **Step 3: Verificar que o menu principal mostra a opção 4**

```bash
bash install.sh
# verificar que aparece "4) System Check" no menu, depois digitar 0 para sair
```

- [ ] **Step 4: Commit final**

```bash
git add .
git commit -m "feat: módulo system-check completo e integrado ao menu principal"
```
