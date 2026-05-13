# Utils — Isotton Tecnologia

Repositorio de utilitarios

## Quick Start

### Ubuntu Desktop (ambiente de desenvolvimento)

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot.sh)"
```

Funciona em Ubuntu 22.04+ com GNOME desktop.

### Servidor Linux (headless)

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot-server.sh)"
```

Configura Docker, Traefik, dnsmasq, runtimes e ferramentas de IA em Ubuntu Server.

Siga as instruções interativas na tela para ambos os modos.

## Pre-requisitos

| Modulo | Sistema | Permissao | Requisitos minimos |
|--------|---------|-----------|-------------------|
| Ubuntu Dev Setup | Ubuntu 22.04+ com GNOME | `sudo` | Acesso a internet |
| Server Setup | Ubuntu 22.04+ Server (headless) | `sudo` | Acesso a internet, IP fixo disponivel na rede |
| Hardware Check | Ubuntu 22.04+ | `sudo` | Acesso a internet (instala ferramentas via apt) |

Os scripts `boot.sh` e `boot-server.sh` instalam automaticamente `git`, `curl` e `wget` antes de clonar o repositorio.

---

## Modulos

O menu principal (`install.sh`) oferece tres modulos:

| # | Modulo | Uso |
|---|--------|-----|
| 1 | Ubuntu Dev Setup | Maquina de desenvolvimento com GNOME |
| 2 | Server Setup | Servidor Linux headless |
| 3 | Hardware Check | Verificacao de integridade de hardware |

---

## Ubuntu Dev Setup

### Core (automatico)

- **Prerequisites** — git, curl, wget, build-essential, libssl-dev, lsof
- **Zsh + Oh My Zsh** — tema Eastwood, plugins: autosuggestions, syntax-highlighting, git, docker, docker-compose, npm, composer, sudo, web-search, z
- **NVM + Node.js LTS** — gerenciador de versoes Node.js com a versao LTS mais recente
- **PHP + Composer** — PHP com extensoes (mysql, xml, mbstring, curl, zip, gd, intl, sqlite3, pgsql) e Composer
- **Docker + Docker Compose** — Docker Engine com plugin Compose
- **Valet Linux** — ambiente de desenvolvimento PHP local (desativa Apache automaticamente)
- **Takeout** — gerenciador de servicos Docker (MySQL, Redis, etc.) via wrapper

### Aplicativos (automatico)

- **Google Chrome** — navegador web
- **VS Code Insiders** — editor de codigo
- **DBeaver** — cliente de banco de dados universal
- **ApiDog** — cliente de API (alternativa ao Postman)
- **Micro** — editor de texto moderno para terminal

### Ferramentas de IA (selecao interativa)

Durante a instalacao, voce escolhe quais instalar:

- **OpenCode** — agente de IA open-source para terminal
- **Claude Code** — CLI da Anthropic para coding
- **GitHub Copilot CLI** — assistente de IA do GitHub para terminal

### Customizacoes Desktop

- Ubuntu Dock: posicao bottom, auto-hide, icones 36px, multi-monitor

---

## Server Setup

Instalacao automatica para servidores headless Ubuntu 22.04+:

- **Rede** — IP estatico configuravel + dnsmasq com wildcard DNS (`*.nome` apontando para o servidor)
- **Docker + Traefik** — Docker Engine, Compose e Traefik como reverse proxy com dashboard
- **Runtimes** — Node.js (via NVM) e PHP com extensoes essenciais
- **Browser** — Chromium + Playwright para automacao
- **Ferramentas de IA** (selecao interativa) — Claude Code e/ou Codex CLI

---

## Hardware Check

Verificacao de integridade de hardware apos instalacao do sistema operacional.

| Componente | Ferramenta | Tempo |
|------------|------------|-------|
| RAM | memtest86+ | reboot (via GRUB) |
| SSD / NVMe | smartctl | ~1 min |
| CPU + RAM sob carga | stress-ng | 5 min |
| Temperatura | lm-sensors | ~10s |

Gera relatorio com status OK/WARN/FAIL e salva em `/tmp/hardware-check-YYYYMMDD.txt`.

---

## Estrutura do Repositorio

```
utils/
├── boot.sh              # Entry point remoto — Ubuntu Dev Setup
├── boot-server.sh       # Entry point remoto — Server Setup
├── install.sh           # Menu interativo de modulos
├── hardware-check.sh    # Verificacao de hardware (standalone)
├── README.md
├── ubuntu-setup/        # Modulo 1: ambiente de desenvolvimento
│   ├── install.sh
│   ├── lib/helpers.sh
│   └── install/
│       ├── core/        # Ferramentas essenciais
│       ├── apps/        # Aplicativos
│       ├── ai-tools/    # Ferramentas de IA (opcional)
│       └── desktop/     # Customizacoes de UI
└── server-setup/        # Modulo 2: servidor headless
    ├── install.sh
    ├── lib/helpers.sh   # Redireciona para ubuntu-setup/lib/helpers.sh
    └── install/
        ├── core/        # Pacotes base
        ├── network/     # IP estatico + dnsmasq
        ├── docker/      # Docker + Traefik
        ├── runtime/     # Node.js + PHP
        ├── browser/     # Chromium + Playwright
        └── ai-tools/    # Claude Code + Codex (opcional)
```

## Execucao Local

Se voce ja clonou o repositorio:

```bash
# Menu de modulos
bash install.sh

# Modulos diretamente
sudo bash ubuntu-setup/install.sh   # Ubuntu Dev Setup
sudo bash server-setup/install.sh   # Server Setup
sudo bash hardware-check.sh         # Hardware Check
```

> **Nota:** O Hardware Check pode ser executado como usuario comum — o script chama `sudo` apenas nos comandos que precisam.

## Branch Alternativa

Para instalar a partir de uma branch especifica:

```bash
# Ubuntu Dev Setup
UTILS_REF=develop bash -c "$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot.sh)"

# Server Setup
UTILS_REF=develop bash -c "$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot-server.sh)"
```

