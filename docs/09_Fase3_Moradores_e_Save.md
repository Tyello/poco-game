# 09 · FASE 3 — Alma dos moradores + Save/Load

> Brief de implementação para o agente de código. Objetivo: fazer o **exílio doer** (apego), dando aos moradores traços, vínculos e micro-histórias — e persistir o jogo (save/load). Ver `docs/02_GDD` (pilar "Gente com nome") e `docs/04_TDD` §6.

## Regras que continuam valendo (não quebrar)

- **O loop validado é sagrado.** Não retunar os números centrais de `sim/balance.gd` (os de recursos, verdade, suspeita, rebelião, exílio). Qualquer efeito novo entra como constante **própria e neutra por padrão**, isolada, para poder ser testada/tunada sem mexer no que já está calibrado.
- Toda aleatoriedade continua passando por `SeededRng` (determinismo).
- `tools/run_tests.gd` continua verde; adicionar testes novos para o que for criado.
- A UI só LÊ o `WorldState` e CHAMA o `SimGame`. Micro-histórias são texto no log — não mudam medidores.

Sugestão: **quatro commits** — Parte 0 (limpeza), A (traços/vínculos), B+C (micro-histórias + exílio humano), D (save/load).

---

## PARTE 0 — Limpeza rápida (retoques da Fase 2b)

1. **Pips de atenção:** mostrar exatamente **3** pips (hoje aparecem 2 com "Atenção: 3"). Corrigir o off-by-one.
2. **Log duplicado:** o registro aparece na coluna esquerda E na Coroa. Manter em **um só lugar** (sugestão: só na Coroa; reaproveitar a coluna esquerda para o histórico rolável de micro-histórias — ver Parte B).
3. **Vermelho de crise:** garantir e verificar que um andar-setor com recurso baixo (< limiar) **tinge de vermelho** e chama atenção. Testar deixando um recurso despencar.
4. **(Opcional) Escada/eixo vertical:** uma tira central ligando os andares, para reforçar a sensação de profundidade (docs/05).

---

## PARTE A — Traços e vínculos (modelo de dados)

### Traços
Cada morador recebe **1–2 traços** de um pool, sorteados via `SeededRng` no `new_game()`. Guardar em `Resident` (ex.: `var traits: Array[String] = []`).

Pool inicial (data-driven, em `sim/balance.gd` ou novo `sim/traits.gd`): por exemplo `cetico`, `devoto`, `leal`, `resmungao`, `curioso`, `medroso`, `tagarela`, `reservado`. Cada traço tem um rótulo legível e textos de sabor (para as micro-histórias).

**Efeitos mecânicos: neutros por padrão.** Se um traço tiver modificador (ex.: `cetico` aumenta levemente a chance de virar `desconfiada`; `devoto` reduz), o modificador entra como constante separada em `balance.gd` **com valor 0.0 por padrão** (desligado), documentado. Assim o *sistema* existe e é testável, mas o balanceamento validado não muda até decidirmos ligar e revalidar. Não altere as fórmulas centrais.

### Vínculos
Gerar alguns **laços** entre moradores no `new_game()` (ex.: 3–4 pares de família/amizade), determinístico via `SeededRng`. Guardar como lista de pares de ids + tipo (ex.: `{"a": id, "b": id, "kind": "familia"}`) no `WorldState`, ou `var bonds: Array[int]` de ids em cada `Resident`. Escolha uma representação simples e serializável.

Os vínculos servem a dois fins: **micro-histórias** (Parte B) e o **exílio humano** (Parte C).

---

## PARTE B — Micro-histórias (o apego)

Um pequeno gerador que emite **linhas de log narrativas** a partir de eventos e do contexto (traços + vínculos). É puramente cosmético — **não muda nenhum medidor**.

Exemplos de gatilhos:
- Alguém vira `sabe`: se tem vínculo, "%s confidenciou o que descobriu a %s." Se é `curioso`/`cetico`, uma variação condizente.
- Alguém é **exilado**: reação dos vínculos — "%s não fala desde que %s foi à Saída." / "Desde a Saída de %s, %s anda calada."
- Alguém é isolado: "%s pergunta todo dia por %s."
- Momentos tranquilos: pequenas cenas de rotina para dar vida (com traços: um `tagarela` espalha um boato inofensivo; um `devoto` lidera uma oração).

Implementação sugerida: um `sim/story.gd` (`RefCounted`) com funções que recebem o `WorldState` + o evento e devolvem uma `String` (ou empurram no log via `SimGame`). Manter os textos data-driven (dicionário de modelos por gatilho/traço) para facilitar expandir.

**Coluna esquerda da UI:** usar como o **feed rolável dessas micro-histórias** (o "diário humano" do Poço), separado do registro mecânico.

Meta emocional (critério de playtest, não de código): depois desta fase, **exilar alguém sobre quem você leu uma micro-história deve dar um aperto**. É esse o teste de sucesso.

---

## PARTE C — Exílio mais humano (aprofundar sem rebalancear)

Hoje o `exile()` já converte, com 50% de chance, **um `ok` aleatório** em `desconfiada` (o efeito mártir). Trocar o alvo: em vez de aleatório, **priorizar um morador com vínculo** com o exilado (se houver); só cai no aleatório se ele não tiver vínculos.

Isso **mantém a mesma probabilidade e magnitude** (balanceamento praticamente idêntico), mas torna o efeito temático e legível: "A Saída do irmão fez %s começar a desconfiar." Rodar `tools/run_sim.gd` algumas vezes e o teste de "ignorar a verdade perde" para confirmar que as taxas seguem equivalentes.

---

## PARTE D — Save / Load

Persistir e restaurar a partida (ver `docs/04_TDD` §6).

- Serializar **apenas o `WorldState`** (nada de nós visuais): `turn`, `attention`, `res`, `suspicion`, `rebellion`, `martyr_floor`, `cons_rate`, `calm_uses`, `exiles`, `exiled_names`, e **cada `Resident`** (id, nome, job, state, isolated, traits, bonds).
- **Determinismo:** salvar também o estado do RNG. Expor em `SeededRng` `get_state()/set_state()` usando `RandomNumberGenerator.state`, e serializar junto. Assim, carregar e continuar produz o mesmo futuro que não ter salvo.
- Campo **`save_version`** desde já, com um ponto único de migração (mesmo que vazio).
- Formato: recurso/JSON em `user://` (ex.: `user://save_1.json`). Um único slot basta para o slice.
- UI: dois botões simples ("Salvar" / "Carregar") no HUD. Ao carregar, reconstruir a apresentação a partir do estado.

---

## Testes a adicionar (em `tools/run_tests.gd`)

1. **Traços atribuídos:** todo morador tem 1–2 traços; determinístico para a mesma seed.
2. **Vínculos determinísticos:** a mesma seed gera os mesmos laços; ids referenciados existem.
3. **Neutralidade do balanceamento:** com os modificadores de traço em 0 (padrão), a taxa de "ignorar a verdade perde" continua ~equivalente à atual (rodar N partidas e comparar a faixa).
4. **Micro-histórias não afetam medidores:** gerar histórias num turno não altera recursos/suspeita/rebelião.
5. **Save/Load round-trip:** salvar → carregar → estado idêntico (inclusive traços, vínculos e estado do RNG); avançar N turnos após carregar == avançar sem ter salvado (mesma seed).
6. **save_version presente** e leitura de save sem versão assume v1.

## Critérios de aceite

- `sim/balance.gd` central intacto; efeitos novos isolados e neutros por padrão.
- Testes todos verdes, incluindo os novos.
- Uma partida mostra micro-histórias humanas no feed; exilar alguém com vínculo gera reação temática.
- Salvar e carregar funciona e é determinístico.
- Print de uma partida com o feed de micro-histórias povoado.

## Fora de escopo

Ligar/tunar os modificadores mecânicos dos traços (fica para uma passada de balanceamento dedicada, revalidada como fizemos no protótipo). Mecânicas de atos futuros (escavação, drones, modo Núcleo). Arte final e som.
