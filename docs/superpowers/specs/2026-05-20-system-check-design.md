# System Check — Design Spec

**Data:** 2026-05-20  
**Status:** Aprovado

---

## Objetivo

Adicionar um 4º módulo ao menu principal (`install.sh`) chamado **System Check** — um script de verificação de saúde do SO em operação. Diferente do `hardware-check.sh` (que testa integridade física de hardware com stress tests), o system-check analisa o estado atual do sistema: armazenamento, performance, serviços, rede, segurança e drivers.

O resultado final é uma tabela colorida com status `OK | WARN | FAIL` para cada item verificado, listando exatamente o que precisa ser corrigido.

---

## Estrutura de arquivos

```
utils/
├── install.sh                      # +opção 4) System Check
├── system-check.sh                 # orquestrador: menu + print_summary
└── system-check/
    └── checks/
        ├── storage.sh
        ├── performance.sh
        ├── services.sh
        ├── network.sh
        └── drivers.sh
```

### Padrão de arquitetura

`system-check.sh` segue exatamente o padrão de `hardware-check.sh`:

- `source "$UTILS_PATH/ubuntu-setup/lib/helpers.sh"` — reutiliza `log_info`, `log_warning`, `log_error`, `ensure_packages`
- `declare -A RESULTS` + função `save_result "componente" "OK|WARN|FAIL" "detalhe"`
- Cada arquivo em `system-check/checks/` é **sourced** pelo orquestrador (compartilha variáveis e helpers)
- Menu interativo: `1) Todas | 2) Armazenamento | 3) Performance | 4) Serviços | 5) Rede | 6) Drivers | 0) Sair`
- `print_summary` — tabela colorida final + salva relatório em `/tmp/system-check-YYYYMMDD-HHMMSS.txt`
- Todos os textos voltados ao usuário em **Português Brasileiro**

---

## Lógica por categoria

### storage.sh

| Verificação | Ferramenta | WARN | FAIL |
|-------------|-----------|------|------|
| Uso de disco por partição | `df -h` | ≥ 85% | ≥ 95% |
| Uso de inodes por partição | `df -i` | ≥ 85% | — |
| Top 5 maiores diretórios em `/` | `du -sh` | — | — (só informativo) |

- Exclui `/proc`, `/sys`, `/dev`, `/run` do `du`
- Um resultado por partição montada relevante (tipo `ext4`, `xfs`, `btrfs`)

### performance.sh

| Verificação | Ferramenta | WARN | FAIL |
|-------------|-----------|------|------|
| Load average (1 min) | `/proc/loadavg` + `nproc` | > nproc | > nproc × 2 |
| RAM livre | `/proc/meminfo` | < 15% total | < 5% total |
| Uso de swap | `/proc/meminfo` | > 50% | > 90% |
| Top 5 processos por CPU | `ps aux` | — | — (só informativo) |
| Top 5 processos por RAM | `ps aux` | — | — (só informativo) |

### services.sh

Lista de serviços conhecidos verificados (apenas os que estiverem **instalados** no sistema):

`docker`, `ssh`, `traefik`, `nginx`, `apache2`, `ufw`, `fail2ban`, `cron`

- Detecta se instalado com `systemctl list-unit-files <serviço>.service 2>/dev/null | grep -q <serviço>`
- Usa `systemctl is-active <serviço>` para cada um que estiver instalado
- Serviço instalado mas **inativo** → `WARN`
- Serviço **não instalado** → `SKIP` (não conta como WARN/FAIL)
- Serviço com status `failed` → `FAIL`

### network.sh

| Verificação | Ferramenta | WARN | FAIL |
|-------------|-----------|------|------|
| Conectividade internet | `ping -c 3 8.8.8.8` | — | sem resposta |
| Portas abertas | `ss -tlnp` | — | só informativo |
| SSH: PermitRootLogin | `/etc/ssh/sshd_config` | `yes` | — |
| SSH: porta padrão | `/etc/ssh/sshd_config` | porta 22 | — |
| Updates pendentes | `apt list --upgradable` | > 0 | > 20 |

### drivers.sh

| Driver | Como detectar | Módulo esperado | WARN se |
|--------|--------------|-----------------|---------|
| GPU (VGA) | `lspci \| grep -i vga` | nvidia / amdgpu / i915 | nenhum módulo carregado |
| Áudio | `lspci \| grep -i audio` | `snd_*` em `lsmod` | nenhum módulo carregado |
| Rede (Ethernet/Wi-Fi) | `lspci \| grep -iE 'ethernet\|wireless\|wi-fi'` | interface ativa em `ip link` | nenhuma interface com link up |

- Se `lspci` não listar o hardware (ex: VM sem GPU física), resultado é `SKIP`

---

## Output esperado

```
==========================================
  Isotton — System Check
==========================================

Componente           Status   Detalhe
-------------------- -------- -------------------------------
Disco /              OK       42% usado (38G/90G)
Disco /home          WARN     87% usado (174G/200G)
Inodes /             OK       12% usado
RAM                  OK       livre: 3.2G / 16G (20%)
Swap                 OK       0% usado
Load Average         OK       0.8 (4 CPUs)
docker               OK       ativo
ssh                  OK       ativo
traefik              WARN     inativo
Internet             OK       8.8.8.8 acessível
SSH Config           WARN     PermitRootLogin yes
Updates Pendentes    FAIL     34 pacotes disponíveis
Driver GPU           OK       nvidia (módulo: nvidia)
Driver Áudio         OK       snd_hda_intel
Driver Rede          OK       enp3s0 (link up)

[WARNING] Verifique os itens com WARN/FAIL antes de continuar.

Relatório salvo em: /tmp/system-check-20260520-143022.txt
```

---

## Integração com install.sh

Adicionar opção `4) System Check` no menu de `install.sh`:

```bash
echo "  4) System Check     - Verificação de saúde do SO (disco, serviços, rede, drivers)"
```

E no `case`:

```bash
4)
    source "$UTILS_PATH/system-check.sh"
    ;;
```

---

## Fora do escopo

- Não substitui nem duplica o `hardware-check.sh` (stress test, memtest, SMART completo)
- Não faz remediação automática — apenas lista o que está fora do padrão
- Não persiste histórico de execuções anteriores
