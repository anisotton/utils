---
name: init-project
description: Inicializa o projeto com seleção de CLI, provider, estrutura de workflows e análise completa
compatibility:
  - opencode
  - claude-code
  - github-copilot
---

# /init - Inicialização de Projeto

Comando para configurar e inicializar projetos com estrutura de workflows, instruções de agente e análise completa.

## O que este comando faz

1. **Identifica o CLI** - Pergunta qual ferramenta de IA o usuário está utilizando (OpenCode ou Claude Code)
2. **Seleciona o provider** (apenas OpenCode) - Pergunta qual provider usar e cria `.opencode/oh-my-opencode.json`
3. **Cria estrutura de workflows** - Pasta `.project/` com subpastas de issues e análises
4. **Gera instruções de agente** - `AGENTS.md` (OpenCode) ou `CLAUDE.md` (Claude Code) na raiz do projeto
5. **Configura .gitignore** - Adiciona `.project/` ao .gitignore do projeto
6. **Analisa o projeto** - Identifica tecnologias, estrutura, funcionalidades e gera documentação
7. **Gera PROJETO.md** - Documento operacional completo em `.project/docs/PROJETO.md`

---

## Workflow de Execução

### Etapa 0: Identificação do CLI

**ANTES de qualquer outra ação**, identificar qual ferramenta de IA o usuário está utilizando.

Usar a ferramenta `question` para coletar:

```
question({
  questions: [
    {
      header: "CLI de IA",
      question: "Qual ferramenta de IA você está utilizando neste projeto?",
      options: [
        { label: "OpenCode", description: "OpenCode CLI (oh-my-opencode)" },
        { label: "Claude Code", description: "Claude Code CLI (Anthropic)" }
      ]
    }
  ]
})
```

Armazenar a resposta como `CLI_CHOICE` para usar nas etapas seguintes.

---

### Etapa 1: Seleção de Provider (apenas OpenCode)

**Executar SOMENTE se `CLI_CHOICE = OpenCode`.**

Se `CLI_CHOICE = Claude Code`, pular esta etapa inteiramente e ir para a Etapa 2.

Usar a ferramenta `question` para coletar a preferência:

```
question({
  questions: [
    {
      header: "Provider",
      question: "Qual provider deseja utilizar neste projeto?",
      options: [
        { label: "GitHub Copilot", description: "Modelos via GitHub Copilot. Prefixo: github-copilot/" },
        { label: "Anthropic", description: "Modelos via Anthropic (Claude). Prefixo: anthropic/" },
        { label: "Google Antigravity", description: "Modelos Gemini via Antigravity. Prefixo: google/" }
      ]
    }
  ]
})
```

#### Mapeamento de Prefixos

| Provider | Prefixo |
|----------|---------|
| GitHub Copilot | `github-copilot/` |
| Anthropic | `anthropic/` |
| Google Antigravity | `google/` |

#### Lógica de Criação do oh-my-opencode.json

1. **Ler** o arquivo global `~/.config/opencode/oh-my-opencode.json`
2. **Identificar** o provider selecionado
3. **Mapear cada agente** para o modelo equivalente do provider escolhido, usando a tabela de equivalências abaixo
4. **Preservar** qualquer campo além de `model` que exista no agente (temperature, etc.)
5. **Gravar** em `.opencode/oh-my-opencode.json` na raiz do projeto
6. **NÃO** copiar o campo `$schema` do global — usar sempre a referência atualizada

#### Tabela de Equivalências por Provider

Cada agente tem um **papel** (orquestrador, raciocínio, busca leve, frontend, escrita, visão). O modelo escolhido deve corresponder ao melhor modelo **daquele provider** para aquele papel.

| Agente | Papel | GitHub Copilot | Anthropic | Google Antigravity |
|--------|-------|----------------|-----------|-------------------|
| sisyphus | Orquestrador principal (forte) | `github-copilot/claude-opus-4.6` | `anthropic/claude-opus-4-6` | `google/antigravity-gemini-3-pro-high` |
| oracle | Raciocínio profundo | `github-copilot/gpt-5.2` | `anthropic/claude-opus-4-6` | `google/antigravity-gemini-3-pro-high` |
| librarian | Busca e referências (leve) | `opencode/glm-4.7-free` | `anthropic/claude-haiku-4` | `google/antigravity-gemini-3-flash` |
| explore | Grep rápido (leve) | `opencode/gpt-5-nano` | `anthropic/claude-haiku-4` | `google/antigravity-gemini-3-flash` |
| frontend-ui-ux-engineer | Frontend/UI | `github-copilot/claude-sonnet-4-6` | `anthropic/claude-sonnet-4-6` | `google/antigravity-gemini-3-pro-low` |
| document-writer | Escrita/documentação | `github-copilot/claude-sonnet-4-6` | `anthropic/claude-sonnet-4-6` | `google/antigravity-gemini-3-pro-low` |
| multimodal-looker | Análise visual/multimodal | `github-copilot/gpt-5.2` | `anthropic/claude-opus-4-6` | `google/antigravity-gemini-3-pro-high` |

> **Nota:** Se o global tiver agentes que NÃO estão nesta tabela, copiar o agente mantendo o modelo original (não trocar).

#### Exemplo de transformação

Global (`~/.config/opencode/oh-my-opencode.json`):
```json
{
  "agents": {
    "sisyphus": { "model": "github-copilot/claude-opus-4.6" },
    "oracle": { "model": "github-copilot/gpt-5.2" },
    "librarian": { "model": "opencode/glm-4.7-free" },
    "explore": { "model": "opencode/gpt-5-nano" }
  }
}
```

Gerado (`.opencode/oh-my-opencode.json`) se escolheu **Anthropic**:
```json
{
  "agents": {
    "sisyphus": { "model": "anthropic/claude-opus-4-6" },
    "oracle": { "model": "anthropic/claude-opus-4-6" },
    "librarian": { "model": "anthropic/claude-haiku-4" },
    "explore": { "model": "anthropic/claude-haiku-4" }
  }
}
```

Gerado se escolheu **GitHub Copilot**:
```json
{
  "agents": {
    "sisyphus": { "model": "github-copilot/claude-opus-4.6" },
    "oracle": { "model": "github-copilot/gpt-5.2" },
    "librarian": { "model": "opencode/glm-4.7-free" },
    "explore": { "model": "opencode/gpt-5-nano" }
  }
}
```

**Se já existir `.opencode/oh-my-opencode.json`**, perguntar se deseja sobrescrever:

```
question({
  questions: [
    {
      header: "Config existente",
      question: "Já existe .opencode/oh-my-opencode.json neste projeto. Deseja sobrescrever com o novo provider?",
      options: [
        { label: "Sobrescrever", description: "Recriar o arquivo com o novo provider selecionado" },
        { label: "Manter atual", description: "Não alterar a configuração existente" }
      ]
    }
  ]
})
```

---

### Etapa 2: Scaffold de Workflows

Verificar e criar (se necessário) a estrutura completa:

```
.project/
├── docs/                        # Documentação do projeto
│   └── PROJETO.md               # Gerado na Etapa 5
│
├── issues/                      # Workflow de issues
│   ├── backlog/
│   ├── pending-validation/
│   ├── validation-feedback/
│   └── executed/
│
└── analises/                    # Workflow de análise de demandas (DDP)
    ├── received/
    ├── in-analysis/
    ├── pending-review/
    ├── approved/
    └── ready-for-dev/
```

**Se `CLI_CHOICE = OpenCode`**, criar também a pasta `.opencode/` para configurações específicas:

```
.opencode/
├── oh-my-opencode.json          # Criado na Etapa 1
└── .gitignore                   # Ignora node_modules/, package.json, bun.lock
```

```bash
mkdir -p .project/docs
mkdir -p .project/issues/{backlog,pending-validation,validation-feedback,executed}
mkdir -p .project/analises/{received,in-analysis,pending-review,approved,ready-for-dev}

grep -q "^\.project" .gitignore 2>/dev/null || echo ".project/" >> .gitignore
```

**Apenas se `CLI_CHOICE = OpenCode`:**
```bash
mkdir -p .opencode

cat > .opencode/.gitignore << 'EOF'
node_modules/
package.json
bun.lock
EOF

grep -q "^\.opencode" .gitignore 2>/dev/null || echo ".opencode/" >> .gitignore
```

**Comportamento idempotente:**
- Se pastas já existem: não sobrescrever
- Se `.gitignore` já lista `.project/`: não duplicar
- Se `.opencode/.gitignore` já existe: não sobrescrever

---

### Etapa 3: Geração do Arquivo de Instruções do Agente

Conforme o CLI escolhido, gerar o arquivo de instruções na raiz do projeto.

#### Se `CLI_CHOICE = OpenCode` → gerar `AGENTS.md`

Criar `AGENTS.md` na raiz do projeto com a listagem de skills disponíveis:

```markdown
# Regras do Projeto

## Skills disponíveis

Use as skills abaixo invocando-as pelo nome quando o contexto for relevante:

- **`workflow-issues`** — Gerenciar ciclo de vida de issues (criar, mover, validar, finalizar)
- **`workflow-analise-demandas`** — Análise técnica de demandas DDP (AS-IS + TO-BE → HOW-TO)
- **`check-documentation`** — Consultar documentação oficial de tecnologias do projeto
- **`laravel-dusk`** — Testes end-to-end com Laravel Dusk
- **`interface-design`** — Design de interfaces (dashboards, painéis, apps)
- **`init-project`** — Inicializar projeto com estrutura de workflows e análise

## Estrutura de Workflows

- Issues: `.project/issues/` (backlog → pending-validation → validation-feedback → executed)
- Análises: `.project/analises/` (received → in-analysis → pending-review → approved → ready-for-dev)
- Documentação: `.project/docs/PROJETO.md`
```

**Se já existir `AGENTS.md`**, perguntar se deseja sobrescrever ou fazer merge.

#### Se `CLI_CHOICE = Claude Code` → gerar `CLAUDE.md`

Criar `CLAUDE.md` na raiz do projeto:

```markdown
# Regras do Projeto

## Skills disponíveis

Use as skills abaixo invocando-as pelo nome quando o contexto for relevante:

- **`workflow-issues`** — Gerenciar ciclo de vida de issues (criar, mover, validar, finalizar)
- **`workflow-analise-demandas`** — Análise técnica de demandas DDP (AS-IS + TO-BE → HOW-TO)
- **`check-documentation`** — Consultar documentação oficial de tecnologias do projeto
- **`laravel-dusk`** — Testes end-to-end com Laravel Dusk
- **`interface-design`** — Design de interfaces (dashboards, painéis, apps)
- **`init-project`** — Inicializar projeto com estrutura de workflows e análise

## Estrutura de Workflows

- Issues: `.project/issues/` (backlog → pending-validation → validation-feedback → executed)
- Análises: `.project/analises/` (received → in-analysis → pending-review → approved → ready-for-dev)
- Documentação: `.project/docs/PROJETO.md`
```

**Se já existir `CLAUDE.md`**, perguntar se deseja sobrescrever ou fazer merge.

> **Nota:** O conteúdo base é o mesmo para ambos os CLIs. A diferença é o nome do arquivo (`AGENTS.md` vs `CLAUDE.md`) pois cada CLI lê seu respectivo arquivo automaticamente.

---

### Etapa 4: Discovery e Análise (Paralelo)

**Disparar agentes explore em background IMEDIATAMENTE:**

```
task(subagent_type="explore", load_skills=[], description="Identificar tech stack e dependências", run_in_background=true, prompt="Analise o projeto para identificar: linguagens de programação, frameworks, bibliotecas principais, runtime (node, php, python, etc), versões quando detectáveis. Verifique package.json, composer.json, pyproject.toml, go.mod, Cargo.toml e similares. Retorne lista estruturada com nome, versão e papel de cada dependência principal.")

task(subagent_type="explore", load_skills=[], description="Mapear estrutura e arquitetura", run_in_background=true, prompt="Mapeie a estrutura do projeto: pastas principais e seu propósito, padrão arquitetural (MVC, Clean, Hexagonal, DDD, etc), entry points, módulos/domínios identificáveis. Analise como o código está organizado e quais são os limites entre módulos. Ignore node_modules, vendor, dist, build. Retorne mapa estruturado.")

task(subagent_type="explore", load_skills=[], description="Identificar comandos e ambiente", run_in_background=true, prompt="Encontre como rodar o projeto: scripts em package.json/composer.json, Makefile, justfile, docker-compose, Dockerfile. Identifique comandos de dev, build, test, lint, deploy. Verifique .env.example para variáveis de ambiente necessárias. Retorne lista de comandos organizados por categoria (setup, dev, test, build, deploy).")

task(subagent_type="explore", load_skills=[], description="Analisar convenções e qualidade", run_in_background=true, prompt="Identifique convenções do projeto: configurações de lint (eslint, phpstan, ruff, etc), formatação (prettier, pint, black), testes (jest, vitest, phpunit, pytest), CI/CD (.github/workflows, gitlab-ci). Analise padrões de naming, imports, estrutura de arquivos. Retorne convenções detectadas e ferramentas de qualidade configuradas.")

task(subagent_type="explore", load_skills=[], description="Identificar funcionalidades e integrações", run_in_background=true, prompt="Identifique as principais funcionalidades/módulos do sistema: autenticação, CRUD, APIs, jobs/filas, integrações externas, webhooks, etc. Para cada funcionalidade, indique localização no código e dependências principais. Retorne lista organizada por domínio/módulo.")
```

**Enquanto agentes rodam, executar no main session:**

```bash
find . -maxdepth 2 -type d -not -path "*/\.*" -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/dist/*" -not -path "*/build/*" | head -40

ls package.json composer.json pyproject.toml Cargo.toml go.mod pom.xml build.gradle Gemfile 2>/dev/null

ls README* 2>/dev/null

git log --oneline -5 2>/dev/null
git remote -v 2>/dev/null
```

---

### Etapa 5: Geração do PROJETO.md

**Coletar resultados dos agentes:**

```
for each task_id: background_output(task_id="...")
```

**Consolidar informações e criar `.project/docs/PROJETO.md`** usando o template abaixo.

Se já existir PROJETO.md:
- Perguntar se deseja atualizar ou manter o atual (a menos que `--force`)

#### Template do PROJETO.md

```markdown
# Projeto: {nome do projeto}

> Documento operacional para agentes de IA. Referência principal para trabalhar neste repositório.
> Prioriza "como executar e como não quebrar" sobre descrições genéricas.

**Gerado em:** {DATA_ATUAL}
**Última atualização:** {DATA_ATUAL}

---

## Snapshot

- **Tipo:** {API / web app / monorepo / lib / CLI / etc}
- **Stack:** {linguagem + framework + runtime}
- **Banco de dados:** {se aplicável}
- **Ambiente:** {Docker / local / cloud}

## Estrutura do Projeto

```
{estrutura de diretórios principais com descrição breve de cada}
```

### Padrão Arquitetural

{MVC, Clean Architecture, Hexagonal, DDD, Monolito, Microservices, etc.}

{1-3 linhas explicando como o código está organizado}

### Módulos/Domínios

| Módulo | Localização | Descrição |
|--------|-------------|-----------|
| {nome} | `{caminho/}` | {o que faz} |

## Como Rodar

### Setup inicial
```bash
{comandos de setup: clone, install, env, migrations, etc}
```

### Desenvolvimento
```bash
{comando para rodar em dev}
```

### Testes
```bash
{comando para rodar testes}
```

### Build
```bash
{comando para build}
```

### Lint/Format
```bash
{comandos de lint e formatação}
```

## Convenções

### Código
- **Naming:** {padrões de nomenclatura detectados}
- **Imports:** {convenção de imports}
- **Estilo:** {prettier/pint/black/etc — configuração detectada}

### Git
- **Commits:** {padrão se detectado, ex: conventional commits}
- **Branches:** {padrão se detectado}

## Dependências Principais

| Dependência | Versão | Papel |
|-------------|--------|-------|
| {dep} | {version} | {para que serve} |

## Integrações Externas

| Sistema/Serviço | Tipo | Descrição |
|-----------------|------|-----------|
| {serviço} | API/SDK/Webhook | {descrição} |

## Riscos e Armadilhas

- {pontos de atenção, débitos técnicos, coisas não-óbvias que podem quebrar}

## Variáveis de Ambiente

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| {var} | Sim/Não | {para que serve} |

---

## Workflows do Projeto

### Issues
Fluxo: `backlog/` → `pending-validation/` → `validation-feedback/` → `executed/`
Localização: `.project/issues/`

### Análises (DDP)
Fluxo: `received/` → `in-analysis/` → `pending-review/` → `approved/` → `ready-for-dev/`
Localização: `.project/analises/`

---

*Gerado automaticamente pelo comando `/init`*
```

---

### Etapa 6: Relatório Final

Apresentar ao usuário:

**Se `CLI_CHOICE = OpenCode`:**
```
=== /init Concluído ===

CLI: OpenCode
Projeto: {nome do projeto}
Tech Stack: {resumo}
Provider: {provider selecionado}

Estruturas:
  [OK] .opencode/oh-my-opencode.json criado ({provider})
  [OK] AGENTS.md criado na raiz do projeto
  [OK] .project/docs/PROJETO.md criado
  [OK] .project/issues/ configurado
  [OK] .project/analises/ configurado
  [OK] .gitignore atualizado

Funcionalidades identificadas: {N}
Comandos mapeados: {lista}

Próximos passos:
  - Revisar .project/docs/PROJETO.md
  - Revisar AGENTS.md e adicionar regras específicas do projeto
  - Rodar /init-deep para gerar AGENTS.md hierárquico (recomendado para projetos grandes)
  - Criar issues em .project/issues/backlog/
  - Usar /start-work para começar desenvolvimento
```

**Se `CLI_CHOICE = Claude Code`:**
```
=== /init Concluído ===

CLI: Claude Code
Projeto: {nome do projeto}
Tech Stack: {resumo}

Estruturas:
  [OK] CLAUDE.md criado na raiz do projeto
  [OK] .project/docs/PROJETO.md criado
  [OK] .project/issues/ configurado
  [OK] .project/analises/ configurado
  [OK] .gitignore atualizado

Funcionalidades identificadas: {N}
Comandos mapeados: {lista}

Próximos passos:
  - Revisar .project/docs/PROJETO.md
  - Revisar CLAUDE.md e adicionar regras específicas do projeto
  - Criar issues em .project/issues/backlog/
```

---

## Flags Disponíveis

| Flag | Descrição |
|------|-----------|
| `--force` | Recria estruturas e arquivos mesmo se existirem (com confirmação) |
| `--skip-analysis` | Cria estruturas e configura CLI, sem análise profunda nem PROJETO.md |
| `--update` | Atualiza apenas PROJETO.md e instruções do agente, mantém estruturas |

---

## Regras Importantes

1. **SEMPRE** perguntar o CLI antes de qualquer outra ação
2. **SEMPRE** perguntar o provider antes de iniciar (apenas OpenCode)
3. **NUNCA** editar o oh-my-opencode.json GLOBAL (`~/.config/opencode/`) — apenas o local do projeto (`.opencode/`)
4. **SEMPRE** ler o oh-my-opencode.json global como base para gerar o local (apenas OpenCode)
5. **NUNCA** sobrescrever arquivos existentes sem confirmação (exceto com `--force`)
6. **SEMPRE** verificar estruturas existentes antes de criar
7. **SEMPRE** adicionar `.project/` ao `.gitignore` do projeto
8. **SEMPRE** adicionar `.opencode/` ao `.gitignore` do projeto (apenas OpenCode)
9. **SEMPRE** gerar o arquivo de instruções correto: `AGENTS.md` para OpenCode, `CLAUDE.md` para Claude Code
10. **SEMPRE** usar TodoWrite para rastrear progresso das etapas
11. **SEMPRE** coletar resultados dos agentes background antes de gerar PROJETO.md
12. **SEMPRE** apresentar relatório final ao usuário
13. **SEMPRE** sugerir `/init-deep` no final para projetos com muitos módulos (apenas OpenCode)

---

## TodoWrite Obrigatório

```
TodoWrite([
  { content: "Identificar CLI (OpenCode ou Claude Code)", status: "pending", priority: "high" },
  { content: "Selecionar provider e criar .opencode/oh-my-opencode.json (se OpenCode)", status: "pending", priority: "high" },
  { content: "Criar estrutura .project/ com workflows", status: "pending", priority: "high" },
  { content: "Gerar arquivo de instruções do agente (AGENTS.md ou CLAUDE.md)", status: "pending", priority: "high" },
  { content: "Disparar agentes explore para análise do projeto", status: "pending", priority: "high" },
  { content: "Coletar resultados e gerar .project/docs/PROJETO.md", status: "pending", priority: "high" },
  { content: "Verificar/atualizar .gitignore do projeto", status: "pending", priority: "medium" },
  { content: "Apresentar relatório final", status: "pending", priority: "medium" }
])
```
