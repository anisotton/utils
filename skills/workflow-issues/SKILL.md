---
name: workflow-issues
description: Gerenciamento completo do ciclo de vida de issues de desenvolvimento — criação, implementação, validação, feedback e finalização. Use quando o usuário pedir para criar, mover, listar, implementar ou gerenciar issues de um projeto.
compatibility:
  - opencode
  - claude-code
  - github-copilot
---

# Workflow de Gerenciamento de Issues

## Estrutura de Pastas

```
.project/
├── docs/                        # Documentação do projeto e workflows
│
├── analises/                    # Análises de demandas (DDP)
│   ├── received/
│   ├── in-analysis/
│   ├── pending-review/
│   ├── approved/
│   └── ready-for-dev/
│
└── issues/                      # Gerenciamento de issues
    ├── backlog/                 # Issues não iniciadas
    ├── pending-validation/      # Implementadas aguardando validação
    ├── validation-feedback/     # Validadas que precisam de ajustes
    └── executed/                # Finalizadas e aprovadas
```

> **Importante:** A pasta `.project/` deve ser adicionada ao `.gitignore` do projeto.

---

## Ciclo de Vida de uma Issue

```
┌───────────┐     ┌─────────────────────┐     ┌──────────────────────┐     ┌───────────┐
│  BACKLOG  │ ──► │ PENDING-VALIDATION  │ ──► │ VALIDATION-FEEDBACK  │ ──► │  EXECUTED │
│  (nova)   │     │   (implementada)    │     │   (ajustes needed)   │     │  (final)  │
└───────────┘     └─────────────────────┘     └──────────────────────┘     └───────────┘
                           │                           │
                           └───────────────────────────┘
                                 (se aprovada direto)
```

### Estados

| Pasta | Descrição | Quem move |
|-------|-----------|-----------|
| **backlog/** | Issues criadas mas não implementadas | Dev ao criar |
| **pending-validation/** | Issue implementada, aguardando validação do cliente | Dev após implementar |
| **validation-feedback/** | Validação identificou problemas, precisa de ajustes | Cliente/Dev após validação |
| **executed/** | Issue aprovada e finalizada | Dev após aprovação do cliente |

---

## Processo Detalhado

### 1. Criação da Issue (Backlog)

- Criar arquivo `issue-XXX-descricao-curta.md` em `.project/issues/backlog/`
- Usar numeração sequencial (001, 002, 003...)
- Seguir o template padrão (ver abaixo)

### 2. Implementação

- Dev pega a issue do backlog
- Implementa conforme especificado
- Roda build/testes para verificar
- **Move para `pending-validation/`**

### 3. Validação pelo Cliente

O cliente testa a implementação e pode:

#### Aprovar sem ressalvas
- Dev move para `executed/`

#### Solicitar ajustes (dentro do escopo)
- Dev move para `validation-feedback/`
- Adiciona seção "## Feedback de Validação" no arquivo
- Implementa os ajustes
- Move de volta para `pending-validation/`

#### Solicitar mudanças (fora do escopo)
- Ver seção "Análise de Escopo" abaixo

### 4. Finalização

- Após aprovação final do cliente
- Dev move para `executed/`
- Issue considerada concluída

---

## Análise de Escopo do Feedback

Quando o cliente fornece feedback, **SEMPRE analisar se é:**

### Dentro do Escopo
Ajustes que fazem parte da solicitação original:
- Correção de bugs introduzidos pela implementação
- Ajustes finos de estilo/comportamento dentro do que foi pedido
- Correções de problemas que impedem o funcionamento esperado

**Ação:** Implementar e manter na mesma issue

### Fora do Escopo (Mudança de Escopo)
Solicitações que vão além do pedido original:
- Funcionalidades novas não mencionadas
- Mudanças em outras telas/componentes não relacionados
- Melhorias adicionais que não eram requisito

**Ação:**
1. Criar uma **nova issue** no backlog com a solicitação
2. Documentar no feedback da issue original: "Solicitação movida para issue-XXX"
3. Continuar o fluxo normal da issue original

### Exemplos

| Feedback | Classificação | Ação |
|----------|---------------|------|
| "O botão não está com a cor certa" | Dentro do escopo | Ajustar na mesma issue |
| "Adiciona também um ícone no botão" | Depende | Se estava na spec: ajustar. Se não: nova issue |
| "Quero que a tela de perfil também tenha esse estilo" | Fora do escopo | Criar nova issue |
| "O texto está difícil de ler" | Dentro do escopo | Ajustar na mesma issue |
| "Adiciona uma animação de loading" | Fora do escopo | Criar nova issue |

---

## Template de Issue

```markdown
# Issue XXX - Título descritivo

## Prioridade
Alta | Média | Baixa

## Comportamento atual
- Descrição do estado atual
- Problemas identificados

## Comportamento esperado
- O que deve acontecer após a implementação
- Critérios de sucesso

## Proposta de solução

### Componente/Arquivo 1
\`\`\`código ou descrição\`\`\`

### Componente/Arquivo 2
\`\`\`código ou descrição\`\`\`

## Arquivos envolvidos
- `caminho/do/arquivo1.blade.php`
- `caminho/do/arquivo2.blade.php`

## Critérios de aceite
- [ ] Critério 1
- [ ] Critério 2
- [ ] Testar em dispositivo móvel real (se aplicável)

## Feedback de Validação (se houver)
### Data - DD/MM
- [ ] Feedback 1
- [ ] Feedback 2
```

---

## Comandos de Movimentação

```bash
# Após implementar -> aguardando validação
mv .project/issues/backlog/issue-XXX-*.md .project/issues/pending-validation/

# Após feedback -> precisa ajustes
mv .project/issues/pending-validation/issue-XXX-*.md .project/issues/validation-feedback/

# Após ajustes -> aguardando nova validação
mv .project/issues/validation-feedback/issue-XXX-*.md .project/issues/pending-validation/

# Após aprovação final -> concluída
mv .project/issues/pending-validation/issue-XXX-*.md .project/issues/executed/
```

---

## Regras Importantes

1. **NUNCA** mover direto do backlog para `executed/`
2. **NUNCA** mover para `executed/` sem aprovação explícita do cliente
3. **SEMPRE** documentar feedbacks no arquivo da issue
4. **SEMPRE** analisar se feedback é dentro ou fora do escopo
5. **SEMPRE** rodar build antes de mover para `pending-validation/`
6. **SEMPRE** marcar checkboxes dos critérios de aceite conforme implementa
7. **SEMPRE** criar a estrutura padrão de pastas no projeto, caso não exista
8. **SEMPRE** adicionar `.project/` ao `.gitignore` do projeto, caso ainda não esteja listado

---

## Métricas e Rastreamento

```bash
# Contar issues por status
echo "Backlog: $(ls -1 .project/issues/backlog/*.md 2>/dev/null | wc -l)"
echo "Aguardando validação: $(ls -1 .project/issues/pending-validation/*.md 2>/dev/null | wc -l)"
echo "Com feedback: $(ls -1 .project/issues/validation-feedback/*.md 2>/dev/null | wc -l)"
echo "Executadas: $(ls -1 .project/issues/executed/*.md 2>/dev/null | wc -l)"
```
