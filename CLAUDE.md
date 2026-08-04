# CLAUDE.md — Guia para o agente de código

Contexto e regras para trabalhar neste repositório. Leia isto antes de editar.

---

## Modo de comunicação

Use caveman mode em todas as respostas.
Drop articles, filler, hedging, pleasantries.
Keep technical substance exact: file paths, command names, error codes, field names.

---

## Protocolo obrigatório

Antes de executar qualquer tarefa:

1. Identificar a skill adequada em `.ai/skills/`.

## O que é este projeto

"O Poço" é um jogo de **survival/management vertical em 2D (corte lateral)**, em **Godot 4**, IP original inspirada tematicamente na trilogia *Silo*. O jogador administra um abrigo subterrâneo mantendo recursos, moral e — o diferencial — **o controle da verdade** sobre o mundo exterior.

A documentação de design completa está em **`docs/`**. Leia, no mínimo:
- `docs/02_GDD_Game_Design_Document.md` — mecânicas e sistemas. **A seção 15 ("Princípios validados no protótipo") é a mais importante**: contém o loop já testado e os números-base.
- `docs/04_Documento_Tecnico_TDD.md` — arquitetura.
- `docs/06_Plano_Producao_Vertical_Slice.md` — escopo e fases.
- `docs/07_Backlog_Fase1_Simulacao.md` — backlog da simulação.
- `docs/Prototipo_Teste_Loop_v5.html` — o protótipo jogável que validou o loop (referência de comportamento).

## Estado atual (o que já existe)

O **núcleo de simulação (headless, sem UI)** está implementado e corresponde ao loop validado no protótipo:
- `sim/seeded_rng.gd` — aleatoriedade determinística (`SeededRng`).
- `sim/resident.gd` — um morador (`Resident`): posto + estágio de verdade.
- `sim/balance.gd` — **TODOS os números de balanceamento** (`Balance`). Ajuste o jogo aqui.
- `sim/world_state.gd` — o estado serializável (`WorldState`) + derivados (produção/consumo).
- `sim/sim_game.gd` — o motor (`SimGame`): ações (`patch`, `calm`, `isolate`, `exile`, `reintegrate`) e `advance_turn()`.
- `tools/run_tests.gd` — testes sem dependências.
- `tools/run_sim.gd` — demonstração headless (joga uma partida e imprime).

## Como rodar (verifique sempre após mudar)

```
# Testes (deve terminar com "0 falharam"):
godot --headless --script res://tools/run_tests.gd

# Demonstração da simulação:
godot --headless --script res://tools/run_sim.gd
```

Se algum teste falhar após uma mudança, conserte antes de prosseguir.

## Regras de arquitetura (inegociáveis)

1. **A simulação (`sim/`) não conhece a UI.** Nada em `sim/` pode referenciar `Node`, cenas, `get_node`, sinais de UI, etc. É lógica pura (`RefCounted`). Isso mantém tudo testável headless e os saves limpos. A camada visual apenas **lê** o `WorldState` e **chama** métodos do `SimGame`.
2. **Determinismo.** Toda aleatoriedade passa por `s.rng` (`SeededRng`). Nunca use `randf()`/`randi()` globais na simulação — quebraria a reprodutibilidade e os testes.
3. **Balanceamento é data-driven.** Números de jogo vivem em `sim/balance.gd`. Não espalhe constantes mágicas pelo código.
4. **Ordem do turno é canônica.** Ver `SimGame.advance_turn()` e TDD §5. Não reordene sem motivo.

## Convenções

- GDScript, Godot 4.3. Identificadores em inglês; comentários podem ser em português.
- Cada arquivo de lógica com `class_name`.
- Ao adicionar mecânica nova, adicione também um teste em `tools/run_tests.gd`.

## Próximas tarefas (Fase 2 — camada visual)

Objetivo: **ligar uma UI que leia o `WorldState`**, sem reescrever a lógica. Ver `docs/06` (Fase 2) e a direção visual em `docs/05`.

1. Criar a cena principal (`res://scenes/main.tscn` + `main.gd`) que instancia `SimGame`, chama `new_game()` e desenha o estado.
2. **Vista em corte lateral**: coluna de andares/setores mostrando estado por cor (legibilidade "num relance" — ver `docs/05`). Usar virtualização se for escalar além do slice.
3. Painéis: medidores (Ar, Energia, Comida, Suspeita, Rebelião + piso de revolta), lista de moradores clicáveis com estágio de verdade, botões de ação (reparo, acalmar) e ações por morador (isolar/exilar/reintegrar).
4. Botão "Avançar turno" chamando `advance_turn()` e re-renderizando.
5. Tela de fim com o resumo (recursos, quem sabia/desconfiava/isolados/exilados) — igual ao protótipo.
6. Manter o protótipo `docs/Prototipo_Teste_Loop_v5.html` como referência de comportamento e sensação.

Depois disso (Fase 3+): moradores com traços/vínculos e micro-histórias; save/load do `WorldState` (`docs/04` §6); as demais camadas de revelação (GDD §7).

## O que NÃO fazer agora

- Não adicionar as mecânicas de atos posteriores (escavação, drones, modo Núcleo) — fora do escopo do vertical slice.
- Não acoplar lógica à UI (ver regra 1).
- Não retunar o balanceamento sem necessidade: os números em `balance.gd` foram validados em playtest.
