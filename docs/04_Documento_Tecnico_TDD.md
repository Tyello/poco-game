# 04 · DOCUMENTO TÉCNICO (TDD) — "O Poço"

> Arquitetura e decisões de engenharia. Foco em viabilidade para equipe pequena e em provar o loop rápido.

---

## 1. Engine: Godot 4 (recomendado)

**Decisão:** desenvolver em **Godot 4** (2D), com **GDScript** para a maior parte da lógica e **C#** apenas se/onde houver gargalo ou preferência de equipe.

### Por que Godot (e não MonoGame)
O jogo é **pesado de UI e de dados** (painéis, medidores, listas de moradores, menus de decisão, tooltips) e leve em ação em tempo real. Nesse perfil:

- **Godot é uma engine completa**: editor visual, sistema de cenas/nós, **sistema de UI (Control nodes) nativo**, tilemap, animação, sinais, serialização — tudo pronto. Chega-se a um protótipo jogável muito mais rápido.
- **MonoGame é um framework de baixo nível** (sem editor, sem UI, sem cenas): você constrói o loop de render, o tilemap, os menus e o save do zero. É o que o *Stardew Valley* usou — mas por escolha de um autor solo que queria controle total e programou ~4,5 anos; não é o caminho para validar um loop rápido.
- **Custo/licença:** Godot é MIT, sem royalties nem taxas.
- **Ecossistema atual:** após a crise de licenciamento da Unity (2023), Godot consolidou-se como a escolha pragmática para indie 2D, com comunidade e ferramentas crescentes.

**Quando reconsiderar:** se a equipe já tiver forte domínio de C#/MonoGame e quiser controle de baixo nível, ou precisar reusar tecnologia específica. Para provar o vertical slice, isso seria otimizar a coisa errada. Unity permanece uma alternativa técnica viável (C#, ecossistema grande), mas sem vantagem clara aqui.

---

## 2. Princípio arquitetural: data-driven

O jogo deve ser **orientado a dados**, não a código hard-coded. Setores, recursos, eventos, traços de morador, camadas de revelação e regras de balanceamento vivem em **arquivos de dados** (Godot `Resource` customizados, JSON ou `.tres`), não espalhados em scripts. Motivos: permite iterar balanceamento sem recompilar, facilita adição de conteúdo (eventos, setores) e viabiliza modding no futuro.

---

## 3. Arquitetura de alto nível

Camadas separando **simulação** de **apresentação** (essencial para testabilidade e para o save):

```
┌─────────────────────────────────────────────┐
│  APRESENTAÇÃO (Godot scenes, Control UI)      │
│  - Vista em corte do Poço (andares)           │
│  - Painéis de medidores, alertas, decisões    │
│  - Detalhe de andar / morador                 │
└───────────────▲───────────────────────────────┘
                │ lê estado, emite comandos (sinais)
┌───────────────┴───────────────────────────────┐
│  SIMULAÇÃO (lógica pura, testável)             │
│  - SimClock (turnos/Vigílias)                  │
│  - Sistemas: Recursos, População, Social,      │
│    Verdade, Facções, Eventos                   │
│  - Estado do mundo (WorldState serializável)   │
└───────────────▲───────────────────────────────┘
                │ carrega/salva
┌───────────────┴───────────────────────────────┐
│  DADOS (Resources/JSON): setores, eventos,     │
│  traços, revelações, tabelas de balanceamento  │
└────────────────────────────────────────────────┘
```

**Regra de ouro:** a camada de Simulação **não conhece** a de Apresentação (sem referências a nós visuais). Isso permite rodar a simulação "headless" para testes automatizados e garante saves limpos.

---

## 4. Modelo de dados central (esboço)

- **WorldState** — raiz serializável: turno atual, Vigília, RNG seed, listas abaixo.
- **Floor** — id, faixa/estrato (Coroa/Meios/Entranhas), tipo de setor, nível de melhoria, estado de dano, lotação, ocupantes.
- **Resident** — id, nome, casta, traços[], necessidades{}, relações[], moral, medo, "sabe da verdade?" (nível de conhecimento), posto atual.
- **ResourcePool** — ar, energia, comida, água, peças, remédios (produção/consumo por turno).
- **SocialState** — moral por estrato, suspeita, rebelião.
- **TruthState** — camada de revelação atual, vetores de conhecimento ativos, flags de segredos.
- **EventDef** (dado) — pré-condições, texto, opções[], efeitos por opção (deltas nos sistemas).
- **RevealLayer** (dado) — gatilhos, verbos destravados, mudanças de regra.

---

## 5. Sistema de turno (SimClock)

O avanço de turno processa sistemas em **ordem determinística** (importante para saves e testes):

1. Produção/consumo de recursos.
2. Necessidades e estado dos moradores.
3. Propagação de conhecimento (a "verdade" espalha por vínculos, como SIR simplificado).
4. Cálculo de suspeita → rebelião.
5. Resolução de crises pendentes; disparo de novos eventos elegíveis.
6. Checagem de condições de vitória/derrota.

Determinismo com **RNG semeado** por run (permite reproduzir bugs e viabiliza a estrutura roguelite).

---

## 6. Save/Load

- Serializar **apenas o WorldState** (simulação), nunca nós visuais. A apresentação é reconstruída a partir do estado ao carregar.
- Formato: recurso Godot binário para o save principal; considerar espelho legível (JSON) em debug.
- **Meta-save** separado para o **Legado** (progressão entre runs) — persiste independentemente das runs individuais.
- Versionar o schema desde o dia 1 (campo `save_version`) para permitir migração.

---

## 7. UI/Apresentação (notas técnicas)

- **Vista em corte:** os 144 andares como uma lista/coluna de nós leves; usar **virtualização** (só instanciar/atualizar andares visíveis) para performance e para escalar até 144 sem custo.
- **Estado por cor/ícone:** cada andar reflete estado via tint/badge, dirigido por dados — legibilidade "num relance" (ver docs 02 §12 e 05).
- **Sistema de decisão:** cena reutilizável de "painel de decisão" alimentada por `EventDef` (dados), para não codar cada evento à mão.
- **Localização:** usar o sistema de i18n do Godot (chaves de tradução) desde o começo; o jogo é text-heavy e provavelmente PT + EN.

---

## 8. Ferramentas e pipeline

- **Controle de versão:** Git + Git LFS para assets binários. `.gitignore` padrão Godot.
- **Editor de conteúdo:** aproveitar o inspetor do Godot para editar `Resource`s de evento/setor; se o volume crescer, um editor externo simples (planilha → JSON) para a biblioteca de eventos.
- **Testes:** framework de teste para GDScript (ex.: GUT) rodando a **Simulação headless** — testar economias, propagação da verdade e condições de fim sem UI.
- **CI (quando fizer sentido):** build automatizado e execução dos testes de simulação.

---

## 9. Metas de plataforma e performance

- **Alvo:** PC (Windows/Linux; macOS desejável). Godot exporta para os três.
- **Performance:** o gargalo é lógica/UI, não render; 144 andares + centenas de moradores é trivial para 2D se a simulação for eficiente (evitar O(n²) na propagação social; usar grafos de vínculo).
- **Controles:** mouse/teclado primeiro; considerar suporte a controle depois (menus navegáveis ajudam num futuro port).

---

## 10. Riscos técnicos e mitigação

| Risco | Impacto | Mitigação |
|---|---|---|
| Acoplar simulação à UI | Saves quebrados, difícil testar | Separação estrita desde o dia 1 (§3) |
| Balanceamento hard-coded | Iteração lenta | Data-driven (§2) + testes headless |
| Propagação social custosa | Queda de FPS com muita gente | Grafo de vínculos + updates incrementais |
| Save incompatível entre versões | Perda de progresso do jogador | `save_version` + migração desde o início |
| Escopo de conteúdo (eventos) | Atraso enorme | Cena de decisão data-driven; começar com poucos eventos no slice |
| Decidir C# vs GDScript tarde | Retrabalho | GDScript por padrão; C# só em gargalo comprovado |

---

## 11. Recomendação de arranque técnico

Construir, nesta ordem, dentro do **vertical slice** (ver doc 06):
1. `WorldState` + `SimClock` headless com 2–3 recursos e avanço de turno (com testes).
2. Vista em corte mínima (10–15 andares) lendo o estado.
3. Sistema de moradores com nome + alocação a postos.
4. Um medidor social (suspeita) + um ciclo de decisão via `EventDef`.
5. Save/load do WorldState.

Se esses cinco passos rodarem e "prenderem" por 30 minutos, a fundação técnica está validada.
