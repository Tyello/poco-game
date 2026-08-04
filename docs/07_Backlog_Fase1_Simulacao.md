# 07 · BACKLOG DETALHADO — FASE 1: Simulação Headless

> Objetivo da Fase 1 (ver doc 06 §5 e doc 04 §11): construir o **núcleo de simulação sem UI** — estado do mundo, relógio de turnos, 3 recursos e condições de fim — com **testes automatizados**. Sem arte, sem interface gráfica. A meta é ter uma economia que rode e seja balanceável via testes/console.

**Definição de "Fase 1 concluída" (Definition of Done):**
- A simulação avança turnos de forma **determinística** (mesma seed → mesmo resultado).
- 3 recursos (energia, comida, ar) produzem/consomem e podem zerar.
- Alocação de trabalhadores a postos altera a produção.
- Condições de vitória/derrota do slice disparam corretamente.
- Save/load do estado funciona (round-trip idêntico).
- Um **harness headless** roda N turnos e imprime/loga o estado.
- Cobertura de testes nos sistemas de recurso, turno e fim de jogo.

**Stack:** Godot 4, GDScript. Testes com **GUT** (Godot Unit Test). Sem nós visuais na camada de simulação.

**Legenda de estimativa:** P (pequeno, ~meio dia) · M (médio, ~1–2 dias) · G (grande, ~3+ dias). Ajuste à velocidade real da equipe após os primeiros tickets.

---

## Épico A — Fundação do projeto e testes

### P1-A1 · Esqueleto do projeto Godot + estrutura de pastas · **P**
Criar projeto Godot 4, definir pastas: `/sim` (lógica pura), `/data` (recursos de dados), `/tests`, `/tools`. Configurar Git + Git LFS e `.gitignore` de Godot.
**Aceite:** projeto abre; estrutura existe; primeiro commit feito.
**Dep:** — (Fase 0)

### P1-A2 · Integrar framework de teste (GUT) · **P**
Instalar/config GUT; criar um teste "hello" que roda via linha de comando (headless).
**Aceite:** `godot --headless` executa a suíte e retorna verde.
**Dep:** P1-A1

### P1-A3 · Utilitário de RNG semeado · **P**
Wrapper de RNG determinístico (`SeededRng`) usado por toda a simulação; seed guardada no estado.
**Aceite:** mesma seed → mesma sequência; teste cobre reprodutibilidade.
**Dep:** P1-A1

---

## Épico B — Modelo de estado (data-driven)

### P1-B1 · `WorldState` serializável · **M**
Classe raiz do estado: `turn:int`, `seed:int`, `resources`, `floors[]`, `population`, `social`, flags. Sem referências a nós visuais.
**Aceite:** instancia com valores iniciais; testes de criação/valores default.
**Dep:** P1-A1

### P1-B2 · `ResourcePool` (energia, comida, ar) · **M**
Estrutura com estoque atual, capacidade, produção e consumo por turno para os 3 recursos.
**Aceite:** getters/setters; clamp em [0, capacidade]; testes de limites.
**Dep:** P1-B1

### P1-B3 · `Floor` mínimo + tipos de setor (dados) · **M**
Definir `Floor` (id, estrato, tipo de setor, nível, lotação) e um catálogo **em dados** (`.tres`/JSON) de 4–5 setores: gerador, fazenda, filtro, oficina, alojamento — cada um com produção/consumo base.
**Aceite:** carregar catálogo de dados; criar coluna de 12–15 andares a partir de config; testes de carga.
**Dep:** P1-B1

### P1-B4 · População como agregado (headcount) · **P**
Nesta fase, população é um **número** com necessidade de consumo (não indivíduos ainda — isso é Fase 3). Campos: total, atribuídos por posto, ociosos.
**Aceite:** consumo escala com população; testes.
**Dep:** P1-B1

### P1-B5 · Tabela de balanceamento em dados · **P**
Externalizar taxas (produção/consumo base, capacidades, custo de manutenção) num recurso de dados editável, não hard-coded.
**Aceite:** alterar um valor no arquivo muda a simulação sem editar scripts.
**Dep:** P1-B2, P1-B3

---

## Épico C — Relógio e sistemas de turno

### P1-C1 · `SimClock` com ordem determinística · **M**
Implementar `advance_turn()` executando os sistemas na ordem canônica (TDD §5): produção/consumo → população → (verdade: stub) → (social: stub) → crises (stub) → checagem de fim.
**Aceite:** um turno altera o estado previsivelmente; teste de ordem de execução.
**Dep:** P1-B1..B4

### P1-C2 · Sistema de Recursos (produção/consumo) · **G**
Calcular, por turno: produção de cada setor conforme trabalhadores alocados e nível; consumo pela população e manutenção; aplicar deltas ao `ResourcePool`.
**Aceite:** cenários testados — superávit, equilíbrio, déficit até zerar; energia insuficiente reduz produção dependente (ex.: filtro sem energia → ar cai).
**Dep:** P1-C1, P1-B5

### P1-C3 · Alocação de trabalhadores a postos · **M**
API para atribuir/remover trabalhadores de setores; produção responde à alocação; ociosos não produzem.
**Aceite:** mover trabalhadores muda a produção no próximo turno; testes.
**Dep:** P1-C2

### P1-C4 · Interdependência de recursos · **M**
Modelar ao menos uma cadeia: energia alimenta filtro (ar) e fazenda (comida). Sem energia, cadeias degradam.
**Aceite:** cortar energia derruba ar e comida de forma testável.
**Dep:** P1-C2

---

## Épico D — Condições de fim

### P1-D1 · Sistema de derrota (colapso físico) · **M**
Detectar recurso vital em zero por X turnos consecutivos → derrota física. Estado de "game over" com causa.
**Aceite:** cenário de asfixia/fome dispara derrota com a causa correta; testes.
**Dep:** P1-C2

### P1-D2 · Condição de vitória do slice (sobrevivência) · **P**
Vitória simples para o slice: sobreviver N turnos mantendo os vitais acima de zero (finais morais completos vêm depois).
**Aceite:** atingir N turnos vivo dispara vitória; teste.
**Dep:** P1-C1

### P1-D3 · Stubs de suspeita/verdade/crise · **P**
Placeholders no pipeline de turno (funções vazias com interface definida) para as Fases 3–4 plugarem sem refatorar o `SimClock`.
**Aceite:** hooks existem e são chamados na ordem certa; testes de que são invocados.
**Dep:** P1-C1

---

## Épico E — Persistência

### P1-E1 · Save/Load do `WorldState` · **M**
Serializar somente o estado de simulação (sem visuais); campo `save_version`. Load reconstrói estado idêntico.
**Aceite:** salvar → carregar → estado igual (round-trip); avançar turnos pós-load é idêntico a não ter salvo (com a mesma seed).
**Dep:** P1-B1..B4

### P1-E2 · Versionamento de schema · **P**
Incluir `save_version` e um ponto único de migração (mesmo que vazio agora).
**Aceite:** load de save sem versão assume v1; teste.
**Dep:** P1-E1

---

## Épico F — Harness e balanceamento

### P1-F1 · Harness headless de execução · **M**
Script CLI (`/tools/run_sim.gd`) que instancia um mundo a partir de config, roda N turnos e imprime o estado por turno (recursos, população, fim).
**Aceite:** `godot --headless --script tools/run_sim.gd` roda e loga uma partida inteira até vitória/derrota.
**Dep:** P1-C1..C4, P1-D1..D2

### P1-F2 · Cenários de balanceamento como testes · **M**
Escrever 4–6 cenários automatizados: equilíbrio sustentável, colapso por superpopulação, blackout em cadeia, recuperação após déficit.
**Aceite:** cada cenário afirma o resultado esperado; roda no CI local.
**Dep:** P1-F1

### P1-F3 · Log/instrumentação básica · **P**
Registrar por turno métricas-chave (recursos, deltas, causa de fim) em formato legível para tuning.
**Aceite:** rodar o harness produz um log analisável.
**Dep:** P1-F1

---

## Ordem sugerida de execução

1. **A1 → A2 → A3** (fundação + testes + RNG)
2. **B1 → B2 → B3 → B4 → B5** (estado e dados)
3. **C1 → C2 → C3 → C4** (turno e recursos)
4. **D1 → D2 → D3** (fim de jogo + stubs)
5. **E1 → E2** (save)
6. **F1 → F2 → F3** (harness e balanceamento)

Caminho crítico: A1 → B1 → C1 → C2 → F1. O resto pode paralelizar se houver mais de uma pessoa.

## Riscos específicos da fase

- **Acoplar lógica à UI por hábito** → proibir `import`/referência a nós visuais em `/sim`; um teste de arquitetura pode checar isso.
- **Balanceamento virar buraco sem fundo** → timeboxar; o objetivo da fase é *rodar e ser ajustável*, não estar divertido ainda.
- **Determinismo quebrado por RNG solto** → todo aleatório passa pelo `SeededRng` (P1-A3); cenários de F2 pegam regressões.

## Saída da Fase 1 (o que destrava a Fase 2)

Com a simulação headless validada por testes, a Fase 2 (vista em corte jogável) apenas **liga uma camada visual que lê este estado** — sem reescrever lógica. É por isso que a separação estrita da §3 do TDD é inegociável.
