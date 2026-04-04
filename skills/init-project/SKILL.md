---
name: init-project
description: Inicializa o projeto com estrutura de workflows, arquivo de instrução do agente e análise completa com Smart Dispatch
compatibility:
  - claude-code
  - opencode
---

# /init - Inicialização de Projeto

Configura a estrutura de trabalho com agentes de IA: pastas de workflow, arquivo de instrução e documentação do projeto.

## O que este comando faz

1. **Pergunta qual CLI** — OpenCode ou Claude Code
2. **Configura o provider** (apenas OpenCode) — pergunta qual provider, padrão GitHub Copilot
3. **Cria `.project/`** — lê as skills disponíveis e cria todas as estruturas de pasta que elas mencionam
4. **Atualiza `.gitignore`** — adiciona `.project/` e `.opencode/` (se aplicável)
5. **Analisa o projeto usando a skill `smart-dispatch`** — subagents paralelos com modelos roteados por complexidade
6. **Gera `.project/docs/PROJECT.md`** — documento operacional completo
7. **Gera o arquivo de instrução** — `AGENTS.md` (OpenCode) ou `CLAUDE.md` (Claude Code)
8. **Apresenta relatório final**

---

## Workflow de Execução

### Etapa 1: Identificação do CLI

**ANTES de qualquer outra ação**, perguntar qual ferramenta de IA o usuário está usando:

> "Qual CLI de IA você está utilizando neste projeto?
> 1. Claude Code (Anthropic)
> 2. OpenCode"

Armazenar como `CLI_CHOICE`.

---

### Etapa 2: Seleção de Provider (apenas OpenCode)

**Executar SOMENTE se `CLI_CHOICE = OpenCode`.**

Perguntar ao usuário qual provider deseja usar, **informando que o padrão é GitHub Copilot**:

> "Qual provider deseja utilizar? (padrão: GitHub Copilot)
> 1. GitHub Copilot ← padrão recomendado
> 2. Anthropic
> 3. Google Antigravity"

Armazenar como `PROVIDER_CHOICE`. Se o usuário confirmar o padrão, usar `GitHub Copilot`.

#### Mapeamento de modelos por provider

| Agente | Papel | GitHub Copilot | Anthropic | Google Antigravity |
|--------|-------|----------------|-----------|-------------------|
| sisyphus | Orquestrador principal | `github-copilot/claude-opus-4.6` | `anthropic/claude-opus-4-6` | `google/antigravity-gemini-3-pro-high` |
| oracle | Raciocínio profundo | `github-copilot/gpt-5.2` | `anthropic/claude-opus-4-6` | `google/antigravity-gemini-3-pro-high` |
| librarian | Busca e referências | `opencode/glm-4.7-free` | `anthropic/claude-haiku-4` | `google/antigravity-gemini-3-flash` |
| explore | Grep rápido | `opencode/gpt-5-nano` | `anthropic/claude-haiku-4` | `google/antigravity-gemini-3-flash` |
| frontend-ui-ux-engineer | Frontend/UI | `github-copilot/claude-sonnet-4-6` | `anthropic/claude-sonnet-4-6` | `google/antigravity-gemini-3-pro-low` |
| document-writer | Escrita/docs | `github-copilot/claude-sonnet-4-6` | `anthropic/claude-sonnet-4-6` | `google/antigravity-gemini-3-pro-low` |
| multimodal-looker | Análise visual | `github-copilot/gpt-5.2` | `anthropic/claude-opus-4-6` | `google/antigravity-gemini-3-pro-high` |

#### Criar `.opencode/oh-my-opencode.json`

1. Ler `~/.config/opencode/oh-my-opencode.json` (arquivo global)
2. Remapear os modelos conforme tabela acima para o provider escolhido
3. Preservar campos além de `model` (temperature, etc.)
4. Gravar em `.opencode/oh-my-opencode.json` (local do projeto)
5. **NÃO** copiar o campo `$schema` do global

**Se já existir `.opencode/oh-my-opencode.json`**, perguntar se deseja sobrescrever.

**Criar `.opencode/.gitignore`:**
```
node_modules/
package.json
bun.lock
```

---

### Etapa 3: Criar estrutura `.project/`

#### 3a. Ler skills disponíveis

Ler os arquivos SKILL.md de todas as skills disponíveis (em `~/.claude/skills/` ou `.claude/skills/`) e identificar quais mencionam estruturas de pasta dentro de `.project/`.

**Skills identificadas e suas estruturas:**

| Skill | Estruturas em `.project/` |
|-------|--------------------------|
| `workflow-issues` | `issues/{backlog,pending-validation,validation-feedback,executed}`, `docs/` |
| `workflow-analise-demandas` | `analises/{received,in-analysis,pending-review,approved,ready-for-dev}`, `docs/` |

> **Nota:** Ao ler as skills, se alguma outra mencionar estruturas em `.project/`, criá-las também.

#### 3b. Criar todas as pastas identificadas

```bash
mkdir -p .project/docs
mkdir -p .project/issues/backlog
mkdir -p .project/issues/pending-validation
mkdir -p .project/issues/validation-feedback
mkdir -p .project/issues/executed
mkdir -p .project/analises/received
mkdir -p .project/analises/in-analysis
mkdir -p .project/analises/pending-review
mkdir -p .project/analises/approved
mkdir -p .project/analises/ready-for-dev
```

**Apenas se `CLI_CHOICE = OpenCode`:**
```bash
mkdir -p .opencode
```

**Comportamento idempotente:** se pasta já existe, não sobrescrever.

---

### Etapa 4: Atualizar `.gitignore`

```bash
grep -q "^\.project" .gitignore 2>/dev/null || echo ".project/" >> .gitignore
```

**Apenas se `CLI_CHOICE = OpenCode`:**
```bash
grep -q "^\.opencode" .gitignore 2>/dev/null || echo ".opencode/" >> .gitignore
```

---

### Etapa 5: Análise do projeto com Smart Dispatch

Invocar a skill `smart-dispatch` para rotear os subagents de análise com o modelo adequado para cada tarefa.

Seguindo as regras de roteamento da `smart-dispatch`, disparar em paralelo:

**[opus] — Arquitetura e estrutura** *(raciocínio complexo)*
```
Agent(
  subagent_type="Explore",
  model="opus",
  run_in_background=true,
  description="Analisar arquitetura do projeto",
  prompt="Mapeie a estrutura do projeto: pastas principais e propósito, padrão arquitetural (MVC, Clean, Hexagonal, DDD, etc), entry points, módulos/domínios identificáveis. Ignore node_modules, vendor, dist, build. Retorne mapa estruturado com padrão arquitetural e limites entre módulos."
)
```

**[sonnet] — Tech stack, integrações e módulos** *(implementação padrão)*
```
Agent(
  subagent_type="Explore",
  model="sonnet",
  run_in_background=true,
  description="Identificar tech stack, dependências e integrações",
  prompt="Analise: linguagens, frameworks, bibliotecas principais, runtime, versões detectáveis. Verifique package.json, composer.json, pyproject.toml, go.mod e similares. Identifique integrações externas (APIs, serviços, webhooks) e principais funcionalidades/módulos do sistema. Para cada módulo, indique localização e dependências. Retorne lista estruturada."
)
```

**[haiku] — Comandos, ambiente e convenções** *(varredura mecânica)*
```
Agent(
  subagent_type="Explore",
  model="haiku",
  run_in_background=true,
  description="Identificar comandos, ambiente e convenções",
  prompt="Encontre como rodar o projeto: scripts em package.json/composer.json, Makefile, docker-compose, Dockerfile. Identifique comandos de dev, build, test, lint, deploy. Verifique .env.example para variáveis de ambiente. Identifique também convenções de lint, formatação, testes e CI/CD. Retorne tudo organizado por categoria."
)
```

**Enquanto agentes rodam, executar no main session:**

```bash
find . -maxdepth 2 -type d -not -path "*/\.*" -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/dist/*" -not -path "*/build/*" | head -40

ls package.json composer.json pyproject.toml Cargo.toml go.mod pom.xml Gemfile 2>/dev/null

ls README* 2>/dev/null

git log --oneline -5 2>/dev/null
git remote -v 2>/dev/null
```

---

### Etapa 6: Gerar `.project/docs/PROJECT.md`

Coletar resultados de todos os subagents e consolidar em `.project/docs/PROJECT.md`:

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
{comandos de setup}
```

### Desenvolvimento
```bash
{comando para rodar em dev}
```

### Testes
```bash
{comando para rodar testes}
```

### Build / Lint
```bash
{comandos de build e formatação}
```

## Convenções

- **Naming:** {padrões detectados}
- **Imports:** {convenção de imports}
- **Estilo:** {configuração detectada}
- **Commits:** {padrão se detectado}

## Dependências Principais

| Dependência | Versão | Papel |
|-------------|--------|-------|
| {dep} | {version} | {para que serve} |

## Integrações Externas

| Sistema/Serviço | Tipo | Descrição |
|-----------------|------|-----------|
| {serviço} | API/SDK/Webhook | {descrição} |

## Variáveis de Ambiente

| Variável | Obrigatória | Descrição |
|----------|-------------|-----------|
| {var} | Sim/Não | {para que serve} |

## Riscos e Armadilhas

- {pontos de atenção, débitos técnicos, coisas não-óbvias que podem quebrar}

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

**Se já existir PROJECT.md**, perguntar se deseja atualizar ou manter.

---

### Etapa 7: Gerar arquivo de instrução do agente

#### Se `CLI_CHOICE = Claude Code` → criar `CLAUDE.md`

```markdown
# Regras do Projeto

## Skills disponíveis

Use as skills abaixo invocando-as pelo nome quando o contexto for relevante:

- **`workflow-issues`** — Gerenciar ciclo de vida de issues (criar, mover, validar, finalizar)
- **`workflow-analise-demandas`** — Análise técnica de demandas DDP (AS-IS + TO-BE → HOW-TO)
- **`smart-dispatch`** — Rotear tarefas para o modelo Claude ideal por complexidade
- **`check-documentation`** — Consultar documentação oficial de tecnologias do projeto
- **`laravel-dusk`** — Testes end-to-end com Laravel Dusk
- **`interface-design`** — Design de interfaces (dashboards, painéis, apps)
- **`init-project`** — Re-inicializar projeto ou atualizar documentação

## Contexto do Projeto

Veja `.project/docs/PROJECT.md` para stack, estrutura, comandos e convenções.

## Estrutura de Workflows

- Issues: `.project/issues/` (backlog → pending-validation → validation-feedback → executed)
- Análises: `.project/analises/` (received → in-analysis → pending-review → approved → ready-for-dev)
```

**Se já existir `CLAUDE.md`**, perguntar se deseja sobrescrever ou fazer merge.

#### Se `CLI_CHOICE = OpenCode` → criar `AGENTS.md`

Mesmo conteúdo acima, mas salvo como `AGENTS.md`.

**Se já existir `AGENTS.md`**, perguntar se deseja sobrescrever ou fazer merge.

---

### Etapa 8: Relatório Final

**Se `CLI_CHOICE = Claude Code`:**
```
=== /init Concluído ===

CLI: Claude Code
Projeto: {nome do projeto}
Tech Stack: {resumo}

Estruturas criadas:
  [OK] CLAUDE.md gerado na raiz do projeto
  [OK] .project/docs/PROJECT.md gerado
  [OK] .project/issues/ configurado
  [OK] .project/analises/ configurado
  [OK] .gitignore atualizado
  [OK] skill smart-dispatch verificada

Funcionalidades identificadas: {N}
Comandos mapeados: {lista}

Próximos passos:
  - Revisar .project/docs/PROJECT.md
  - Revisar CLAUDE.md e adicionar regras específicas do projeto
  - Criar issues em .project/issues/backlog/
```

**Se `CLI_CHOICE = OpenCode`:**
```
=== /init Concluído ===

CLI: OpenCode
Projeto: {nome do projeto}
Tech Stack: {resumo}
Provider: {provider selecionado}

Estruturas criadas:
  [OK] .opencode/oh-my-opencode.json criado ({provider})
  [OK] AGENTS.md gerado na raiz do projeto
  [OK] .project/docs/PROJECT.md gerado
  [OK] .project/issues/ configurado
  [OK] .project/analises/ configurado
  [OK] .gitignore atualizado

Funcionalidades identificadas: {N}
Comandos mapeados: {lista}

Próximos passos:
  - Revisar .project/docs/PROJECT.md
  - Revisar AGENTS.md e adicionar regras específicas do projeto
  - Criar issues em .project/issues/backlog/
```

---

## Flags Disponíveis

| Flag | Descrição |
|------|-----------|
| `--force` | Recria todos os arquivos mesmo se existirem (com confirmação) |
| `--skip-analysis` | Cria estruturas e configura CLI, sem análise nem PROJECT.md |
| `--update` | Atualiza apenas PROJECT.md e arquivo de instrução, mantém estruturas |

---

## Regras Importantes

1. **SEMPRE** verificar a skill smart-dispatch antes de qualquer outra ação
2. **SEMPRE** perguntar o CLI antes de criar qualquer arquivo
3. **SEMPRE** perguntar o provider antes de configurar OpenCode (padrão: GitHub Copilot)
4. **NUNCA** editar o `oh-my-opencode.json` GLOBAL — apenas o local do projeto
5. **NUNCA** sobrescrever arquivos existentes sem confirmação (exceto com `--force`)
6. **SEMPRE** ler as skills disponíveis para identificar estruturas a criar em `.project/`
7. **SEMPRE** adicionar `.project/` ao `.gitignore`
8. **SEMPRE** adicionar `.opencode/` ao `.gitignore` (apenas OpenCode)
9. **SEMPRE** usar Smart Dispatch para rotear os subagents de análise por complexidade
10. **SEMPRE** coletar resultados dos subagents antes de gerar PROJECT.md
11. **SEMPRE** apresentar relatório final
