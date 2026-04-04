---
name: workflow-analise-demandas
description: Análise técnica de demandas seguindo o modelo DDP (Documento de Definição de Projeto) — recebe AS-IS e TO-BE, produz HOW-TO com estimativas, cronograma e riscos. Use quando o usuário pedir para analisar uma demanda, criar um HOW-TO, estimar esforço ou revisar um DDP.
compatibility:
  - opencode
  - claude-code
  - github-copilot
---

# Workflow de Análise de Demandas (DDP)

## Contexto

O DDP é composto por três partes:

| Documento | Responsável | Conteúdo |
|-----------|-------------|----------|
| **AS-IS** | Solicitante/Área | Processo atual, fluxos existentes, problemas |
| **TO-BE** | Solicitante/Área | Projeto desejado, escopo, regras de negócio |
| **HOW-TO** | Equipe Técnica (Agente) | Análise técnica, estimativas, cronograma |

**Papel do Agente:** Receber AS-IS + TO-BE e produzir o HOW-TO (análise técnica).

---

## Estrutura de Pastas

```
.project/
├── docs/                        # Documentação do projeto e workflows
│
├── analises/                    # Análises de demandas (DDP)
│   ├── received/                # Demandas recebidas aguardando análise
│   ├── in-analysis/             # Demandas em análise pelo agente
│   ├── pending-review/          # Análise concluída, aguardando aprovação
│   ├── approved/                # Análises aprovadas pelo usuário
│   └── ready-for-dev/           # Prontas para gerar issues
│
└── issues/                      # Gerenciamento de issues
    ├── backlog/
    ├── pending-validation/
    ├── validation-feedback/
    └── executed/
```

> **Importante:** A pasta `.project/` deve ser adicionada ao `.gitignore` do projeto.

---

## Ciclo de Vida de uma Análise

```
┌───────────┐     ┌──────────────┐     ┌────────────────┐     ┌───────────┐     ┌───────────────┐
│ RECEIVED  │ ──► │ IN-ANALYSIS  │ ──► │ PENDING-REVIEW │ ──► │ APPROVED  │ ──► │ READY-FOR-DEV │
│ (entrada) │     │ (agente)     │     │ (validação)    │     │ (aceito)  │     │ (issues)      │
└───────────┘     └──────────────┘     └────────────────┘     └───────────┘     └───────────────┘
                                                │                    │
                                                └────────────────────┘
                                                   (se reprovada: volta para in-analysis)
```

### Estados

| Pasta | Descrição | Quem Move |
|-------|-----------|-----------|
| **received/** | Documento recebido com AS-IS e TO-BE | Usuário ao enviar |
| **in-analysis/** | Agente realizando análise técnica | Agente ao iniciar |
| **pending-review/** | Análise técnica concluída, aguardando validação | Agente ao concluir |
| **approved/** | Análise aprovada pelo usuário | Usuário ao aprovar |
| **ready-for-dev/** | Pronta para gerar issues no backlog | Usuário/Agente |

---

## Processo Detalhado

### 1. Recebimento da Demanda

**Gatilho:** Usuário envia documento com AS-IS e TO-BE preenchidos.

**Ações do Agente:**
1. Criar arquivo `analise-XXX-descricao-curta.md` em `.project/analises/received/`
2. Validar completude das informações recebidas (ver checklist abaixo)
3. Se incompleto: solicitar informações faltantes ao usuário
4. Se completo: mover para `in-analysis/`

**Checklist de Validação AS-IS:**
- [ ] Atores/responsáveis identificados
- [ ] Fluxograma ou descrição do processo atual
- [ ] Ferramentas utilizadas listadas
- [ ] Problemas/gargalos documentados

**Checklist de Validação TO-BE:**
- [ ] Objetivos SMART definidos
- [ ] Escopo com entregáveis listados
- [ ] Regras de negócio especificadas
- [ ] Validadores/aprovadores identificados

### 2. Análise Técnica (HOW-TO)

**Responsável:** Agente

**Ações:**
1. Mover arquivo para `in-analysis/`
2. Analisar requisitos funcionais e não-funcionais
3. Identificar componentes/módulos necessários
4. Mapear integrações com sistemas existentes
5. Estimar esforço por componente
6. Propor cronograma de entrega
7. Documentar a análise técnica no formato HOW-TO
8. Mover para `pending-review/`

**Checklist da Análise Técnica (HOW-TO):**
- [ ] Tecnologias envolvidas documentadas
- [ ] Arquitetura proposta com diagramas (quando aplicável)
- [ ] Plano de integração (se houver sistemas externos)
- [ ] Levantamento de funcionalidades detalhado
- [ ] Estimativa de esforço (horas/dias)
- [ ] Cronograma proposto com marcos de entrega
- [ ] Riscos e dependências identificados

### 3. Revisão pelo Usuário

**Gatilho:** Análise movida para `pending-review/`

**Possíveis Resultados:**

#### Aprovada
- Usuário move para `approved/`
- Adiciona observações se necessário

#### Ajustes Necessários
- Agente move de volta para `in-analysis/`
- Adiciona seção "## Feedback de Revisão" no arquivo
- Realiza ajustes solicitados
- Move novamente para `pending-review/`

### 4. Aprovação Final

**Gatilho:** Análise em `approved/`

**Ações:**
1. Usuário confirma que análise está pronta para desenvolvimento
2. Mover para `ready-for-dev/`
3. Análise técnica (HOW-TO) pode ser incluída no documento original

---

## Estrutura do Output (Análise Técnica)

```markdown
# Análise Técnica (HOW-TO)

## Tecnologias Envolvidas

| Tecnologia | Versão | Finalidade |
|------------|--------|------------|
| [Linguagem/Framework] | [Versão] | [Para que será usado] |

## Arquitetura Proposta

### Visão Geral
[Descrição da arquitetura]

### Diagrama de Componentes
[Diagrama ou descrição dos componentes]

### Fluxo de Dados
[Como os dados transitam entre componentes]

## Levantamento de Funcionalidades

### Módulo/Componente 1
- **Funcionalidade:** [Nome]
- **Descrição:** [O que faz]
- **Regras aplicadas:** [Referência às regras de negócio do TO-BE]
- **Estimativa:** [X horas/dias]

## Plano de Integração

| Sistema | Tipo de Integração | Protocolo | Observações |
|---------|-------------------|-----------|-------------|
| [Sistema] | [API/Webhook/BD] | [REST/SOAP/etc] | [Notas] |

## Estimativa de Esforço

| Fase | Atividade | Esforço |
|------|-----------|---------|
| Desenvolvimento | [Componente/Módulo] | X horas |
| Testes | [Tipo de teste] | X horas |
| Implantação | [Atividades] | X horas |
| **Total** | | **X horas** |

## Cronograma Proposto

| Marco | Data Prevista | Entregável |
|-------|---------------|------------|
| Início | [Data] | Kickoff |
| Entrega 1 | [Data] | [O que será entregue] |
| Entrega Final | [Data] | [Escopo completo] |

## Riscos e Dependências

| Risco/Dependência | Impacto | Mitigação |
|-------------------|---------|-----------|
| [Descrição] | Alto/Médio/Baixo | [Ação preventiva] |

## Premissas

- [Premissa 1]
- [Premissa 2]
```

---

## Comandos de Movimentação

```bash
# Demanda recebida -> iniciar análise
mv .project/analises/received/analise-XXX-*.md .project/analises/in-analysis/

# Análise concluída -> aguardando revisão
mv .project/analises/in-analysis/analise-XXX-*.md .project/analises/pending-review/

# Revisão com feedback -> voltar para análise
mv .project/analises/pending-review/analise-XXX-*.md .project/analises/in-analysis/

# Revisão aprovada -> aprovada
mv .project/analises/pending-review/analise-XXX-*.md .project/analises/approved/

# Aprovada -> pronta para desenvolvimento
mv .project/analises/approved/analise-XXX-*.md .project/analises/ready-for-dev/
```

---

## Regras Importantes

1. **NUNCA** iniciar análise técnica sem AS-IS e TO-BE completos
2. **NUNCA** mover para `approved/` sem validação explícita do usuário
3. **SEMPRE** documentar premissas e riscos identificados
4. **SEMPRE** validar completude do documento recebido antes de analisar
5. **SEMPRE** incluir estimativas baseadas em evidências (comparação com projetos similares)
6. **SEMPRE** criar a estrutura padrão de pastas no projeto, caso não exista
7. **SEMPRE** perguntar ao usuário quando houver ambiguidade nas regras de negócio
8. **SEMPRE** adicionar `.project/` ao `.gitignore` do projeto, caso ainda não esteja listado

---

## Integração com Workflow de Issues

Após uma análise ser movida para `ready-for-dev/`:

1. O levantamento de funcionalidades pode ser convertido em issues
2. Cada módulo/componente pode virar uma ou mais issues em `.project/issues/backlog/`
3. Seguir a skill `workflow-issues` para gerenciamento das issues criadas

---

## Métricas e Rastreamento

```bash
# Contar análises por status
echo "Recebidas: $(ls -1 .project/analises/received/*.md 2>/dev/null | wc -l)"
echo "Em análise: $(ls -1 .project/analises/in-analysis/*.md 2>/dev/null | wc -l)"
echo "Aguardando revisão: $(ls -1 .project/analises/pending-review/*.md 2>/dev/null | wc -l)"
echo "Aprovadas: $(ls -1 .project/analises/approved/*.md 2>/dev/null | wc -l)"
echo "Prontas para dev: $(ls -1 .project/analises/ready-for-dev/*.md 2>/dev/null | wc -l)"
```
