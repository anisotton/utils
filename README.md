# Utils — Isotton Tecnologia

Repositorio de utilitarios

## Quick Start

Execute no terminal

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot.sh)"
```

Siga as instruções interativas na tela. Funciona em Ubuntu 22.04+ com GNOME desktop.

## O que e instalado

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

## Estrutura do Repositorio

```
utils/
├── boot.sh              # Entry point remoto (one-liner)
├── install.sh           # Menu interativo de modulos
├── README.md
└── ubuntu-setup/        # Setup de ambiente Ubuntu
    ├── install.sh       # Orquestrador
    ├── lib/helpers.sh   # Funcoes compartilhadas
    └── install/
        ├── core/        # Ferramentas essenciais (ordem numerica)
        ├── apps/        # Aplicativos
        ├── ai-tools/    # Ferramentas de IA (opcional)
        └── desktop/     # Customizacoes de UI
```

## Execucao Local

Se voce ja clonou o repositorio, pode executar direto:

```bash
sudo ./ubuntu-setup/install.sh
```

## Branch Alternativa

Para instalar a partir de uma branch especifica:

```bash
UTILS_REF=develop bash -c "$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot.sh)"
```

