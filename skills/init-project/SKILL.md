---
name: init-project
description: Inicializa o projeto com seleção de provider, estrutura de workflows e análise completa
compatibility:
  - opencode
  - claude-code
  - github-copilot
---

# /init - Inicialização de Projeto

Comando para configurar e inicializar projetos no OpenCode com oh-my-opencode.

## O que este comando faz

1. **Seleciona o provider** - Pergunta qual provider usar e cria `.opencode/oh-my-opencode.json` no projeto
2. **Cria estrutura de workflows** - Pasta `.opencode/` com subpastas de issues e análises
3. **Configura .gitignore** - Adiciona `.opencode/` ao .gitignore do projeto
4. **Analisa o projeto** - Identifica tecnologias, estrutura, funcionalidades e gera documentação
5. **Gera PROJETO.md** - Documento operacional completo em `.opencode/docs/PROJETO.md`

---

## Workflow de Execução

### Etapa 1: Seleção de Provider

**ANTES de qualquer outra ação**, perguntar ao usuário qual provider deseja utilizar neste projeto.

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
.opencode/
├── oh-my-opencode.json          # Criado/atualizado na Etapa 1
├── .gitignore                   # Ignora arquivos gerados pelo OpenCode
├── docs/                        # Documentação do projeto
│   └── PROJETO.md               # Gerado na Etapa 4
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

```bash
mkdir -p .opencode/docs
mkdir -p .opencode/issues/{backlog,pending-validation,validation-feedback,executed}
mkdir -p .opencode/analises/{received,in-analysis,pending-review,approved,ready-for-dev}

cat > .opencode/.gitignore << 'EOF'
node_modules/
package.json
bun.lock
EOF

grep -q "^\.opencode" .gitignore 2>/dev/null || echo ".opencode/" >> .gitignore
```

**Comportamento idempotente:**
- Se pastas já existem: não sobrescrever
- Se `.opencode/.gitignore` já existe: não sobrescrever
- Se `.opencode/` já está no `.gitignore` do projeto: não duplicar

---

### Etapa 3: Discovery e Análise (Paralelo)

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

### Etapa 4: Geração do PROJETO.md

**Coletar resultados dos agentes:**

```
for each task_id: background_output(task_id="...")
```

**Consolidar informações e criar `.opencode/docs/PROJETO.md`** usando o template abaixo.

Se já existir PROJETO.md:
- Perguntar se deseja atualizar ou manter o atual (a menos que `--force`)

#### Template do PROJETO.md

```markdown
# Projeto: {nome do projeto}

> Documento operacional para agentes OpenCode. Referência principal para trabalhar neste repositório.
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

## Workflows OpenCode

### Issues
Fluxo: `backlog/` → `pending-validation/` → `validation-feedback/` → `executed/`
Localização: `.opencode/issues/`

### Análises (DDP)
Fluxo: `received/` → `in-analysis/` → `pending-review/` → `approved/` → `ready-for-dev/`
Localização: `.opencode/analises/`

---

*Gerado automaticamente pelo comando `/init` do OpenCode*
```

---

### Etapa 5: Relatório Final

Apresentar ao usuário:

```
=== /init Concluído ===

Projeto: {nome do projeto}
Tech Stack: {resumo}
Provider: {provider selecionado} → .opencode/oh-my-opencode.json

Estruturas:
  [OK] .opencode/oh-my-opencode.json criado ({provider})
  [OK] .opencode/docs/PROJETO.md criado
  [OK] .opencode/issues/ configurado
  [OK] .opencode/analises/ configurado
  [OK] .opencode/.gitignore criado
  [OK] .gitignore atualizado

Funcionalidades identificadas: {N}
Comandos mapeados: {lista}

Próximos passos:
  - Revisar .opencode/docs/PROJETO.md
  - Rodar /init-deep para gerar AGENTS.md hierárquico (recomendado para projetos grandes)
  - Criar issues em .opencode/issues/backlog/
  - Usar /start-work para começar desenvolvimento
```

---

## Flags Disponíveis

| Flag | Descrição |
|------|-----------|
| `--force` | Recria estruturas e arquivos mesmo se existirem (com confirmação) |
| `--skip-analysis` | Cria estruturas e configura provider, sem análise profunda nem PROJETO.md |
| `--update` | Atualiza apenas PROJETO.md e oh-my-opencode.json, mantém estruturas |

---

## Regras Importantes

1. **SEMPRE** perguntar o provider antes de iniciar
2. **NUNCA** editar o oh-my-opencode.json GLOBAL (`~/.config/opencode/`) — apenas o local do projeto (`.opencode/`)
3. **SEMPRE** ler o oh-my-opencode.json global como base para gerar o local
4. **NUNCA** sobrescrever arquivos existentes sem confirmação (exceto com `--force`)
5. **SEMPRE** verificar estruturas existentes antes de criar
6. **SEMPRE** adicionar `.opencode/` ao `.gitignore` do projeto
7. **SEMPRE** criar `.opencode/.gitignore` com `node_modules/`, `package.json` e `bun.lock`
8. **SEMPRE** usar TodoWrite para rastrear progresso das etapas
9. **SEMPRE** coletar resultados dos agentes background antes de gerar PROJETO.md
10. **SEMPRE** apresentar relatório final ao usuário
11. **SEMPRE** sugerir `/init-deep` no final para projetos com muitos módulos

---

## TodoWrite Obrigatório

```
TodoWrite([
  { content: "Selecionar provider e criar .opencode/oh-my-opencode.json do projeto", status: "pending", priority: "high" },
  { content: "Criar estrutura .opencode/ com workflows e .gitignore", status: "pending", priority: "high" },
  { content: "Disparar agentes explore para análise do projeto", status: "pending", priority: "high" },
  { content: "Coletar resultados e gerar .opencode/docs/PROJETO.md", status: "pending", priority: "high" },
  { content: "Verificar/atualizar .gitignore do projeto", status: "pending", priority: "medium" },
  { content: "Apresentar relatório final e sugerir /init-deep", status: "pending", priority: "medium" }
])
```
