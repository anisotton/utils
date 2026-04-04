---
name: smart-dispatch
description: Roteia tarefas automaticamente para o modelo Claude ideal (opus/sonnet/haiku) com base na complexidade. Use ao implementar features, corrigir bugs ou qualquer trabalho de desenvolvimento em múltiplas etapas.
compatibility:
  - claude-code
---

# Smart Model Dispatch

Roteia subtarefas para o modelo mais eficiente, reduzindo custo e tempo sem sacrificar qualidade.

## Regras de Roteamento

### opus — Raciocínio complexo e arquitetura
- Planejamento e design de arquitetura
- Implementação de lógica de negócio complexa
- Análise de requisitos e tomada de decisões técnicas
- Revisão de código de alto nível

### sonnet — Implementação padrão
- Lógica de negócio (use cases, repositórios, stores)
- Implementação de telas/componentes com lógica
- Integração com APIs e serviços externos
- Refatoração de código existente

### haiku — Tarefas rápidas e mecânicas
- Geração de arquivos de estilo
- Arquivos de tradução (i18n)
- Criação de boilerplate e mocks
- Escrita de testes unitários
- Varredura de convenções e listagem de arquivos

## Exemplo de Dispatch Paralelo

**Implementar feature de autenticação:**

1. `[opus]`   Planeja arquitetura (fluxo, tokens, refresh)
2. `[sonnet]` Implementa domain + data layers
3. `[sonnet]` Implementa screens com lógica
4. `[haiku]`  Gera estilos, mocks e testes

## Como usar no Claude Code

Ao criar subagents via Agent tool, especifique o parâmetro `model`:

```
opus   → model: "opus"
sonnet → model: "sonnet"
haiku  → model: "haiku"
```
