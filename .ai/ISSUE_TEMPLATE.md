# Framework de criação de issues — Indiciário

Este documento define **como** uma issue do Indiciário deve ser especificada. Ele não cria nenhuma issue por si só: é a convenção + o esqueleto preenchível. Toda issue carrega obrigatoriamente o **conjunto de impacto documental** (ver `docs/INDICE_DOCUMENTACAO.md`).

> Use junto com a skill `to-issues` (`.ai/skills/to-issues.md`), que decompõe PRD/roadmap/playtest em issues pequenas, e com `to-prd` quando o escopo for grande.

---

## Princípios de uma boa issue

1. **Pequena e independente.** Cabe em uma PR revisável. Se não cabe, vire PRD primeiro (`to-prd`) e decomponha (`to-issues`).
2. **Verificável.** Tem critério de aceite objetivo e comandos que provam que passou.
3. **Não-destrutiva por padrão.** Não muta artefatos canônicos nem narrativa dos casos sem evidência de playtest.
4. **TDD quando toca código.** RED explícito antes de GREEN; regressão da suíte como passo final.
5. **Agrupável.** Issues fortemente acopladas podem virar uma PR só (ex.: `25+26`); declare o agrupamento no título.
6. **Honesta sobre limitações.** Não promete bundling, isolamento, Gate Evaluator, Learning Loop ou LLM real antes da issue correspondente.

## Dois arquivos por issue

O fluxo do projeto usa dois artefatos por issue, em `.ai/issues/`:

- `ISSUE-XX_SPEC.md` — **spec técnica completa**: contexto, contrato, regras nomeadas, casos de teste, restrições.
- `ISSUE-XX.md` — **passos do orquestrador**: a sequência de steps que o Claude Code executa.

Issues agrupadas usam o nome combinado nos dois arquivos (ex.: `ISSUE-25+26_SPEC.md` e `ISSUE-25+26.md`).

## Restrições arquiteturais padrão

A menos que a issue declare exceção explícita e justificada:

- sem chamadas a LLM, sem internet, sem rede;
- sem mutação de artefatos existentes (canônicos, baselines, manifests);
- sem duplicação de dataclasses entre módulos;
- `additionalProperties: false` em todo schema novo;
- `ruff` limpo em todos os arquivos novos/alterados;
- `pytest tests/ -q` passa sem regressão.

---

## Esqueleto: `ISSUE-XX_SPEC.md`

```markdown
# ISSUE-XX — <título curto e específico>

## Contexto
<por que esta issue existe; qual lacuna/playtest/auditoria a originou; link p/ doc de origem>

## Objetivo
<resultado observável em uma frase>

## Fora de escopo
<o que esta issue NÃO faz, para não inchar a PR>

## Contrato / regras
<regras nomeadas e testáveis, ex.: RM_001..RM_008; schemas afetados; campos>

## Impacto documental  ← OBRIGATÓRIO
Consultar docs/INDICE_DOCUMENTACAO.md (coluna "Atualizar quando" + gatilhos reversos).
- [ ] <doc 1> — motivo: <por que será tocado>
- [ ] <doc 2> — motivo: <...>
- [ ] docs/INDICE_DOCUMENTACAO.md — se esta issue cria/move/aposenta algum doc
Se nenhum doc precisar mudar, declarar explicitamente: "Sem impacto documental, porque <motivo>".

## Casos de teste (TDD)
<lista de testes RED a escrever antes da implementação; fixtures necessárias>

## Restrições arquiteturais
<herdar as padrão; listar exceções justificadas>

## Critério de aceite
- [ ] regras <...> implementadas e cobertas por teste
- [ ] pytest tests/ -q passa sem regressão
- [ ] ruff limpo nos arquivos tocados
- [ ] impacto documental resolvido (✅ atualizado ou ⏭️ avaliado e não necessário)
- [ ] validator strict dos canônicos passa, quando a issue toca blueprint/schema/validator
```

## Esqueleto: `ISSUE-XX.md` (passos do orquestrador)

```markdown
# ISSUE-XX — passos

Skill: <tdd | diagnose | grill-with-docs | ...> — motivo: <...>

STEP-01 reading      — ler SPEC, docs de impacto declarado e código alvo
STEP-02 red          — escrever testes que falham
STEP-03 green        — implementar até passar
STEP-04 refactor     — limpar sem mudar comportamento
STEP-05 docs         — aplicar o conjunto de impacto documental declarado no SPEC
STEP-06 validation   — pytest completo + ruff + validators strict aplicáveis
STEP-07 wrap-up      — listar arquivos alterados, comandos rodados, impacto documental resolvido

Auto-approve: reading, baseline, documentation, wrap-up.
Revisor obrigatório: red, green, refactor, validation, correction.
```

> Note o **STEP-05 docs** dedicado: o impacto documental declarado no SPEC vira um passo executável, não uma lembrança opcional.

> **Campo `STATUS` único.** Cada `ISSUE-XX.md` carrega só um campo `STATUS` machine-readable (bloco no topo: `ready`/`done`/`blocked`), atualizado a cada wrap-up. Não repetir estado em prosa solta tipo "**Status:** especificada, pronta para execução" em outro ponto do arquivo — vira header contraditório quando a issue evolui e a prosa não acompanha (ver DIV-11 da auditoria de julho/2026).

---

## Checklist de fechamento (reflete o critério de tarefa concluída de `AGENTS.md`)

- [ ] skill usada informada, com motivo;
- [ ] arquivos alterados listados;
- [ ] comandos executados listados, com resultados ou limitações;
- [ ] `pytest tests/ -q` sem regressão;
- [ ] **conjunto de impacto documental resolvido** — cada doc ✅ atualizado ou ⏭️ avaliado e não necessário;
- [ ] mudanças não vazam gabarito para documentos de jogador;
- [ ] PR explica o que mudou, por que e como foi validado.
