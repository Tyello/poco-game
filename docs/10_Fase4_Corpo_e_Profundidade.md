# 10 · FASE 4 — Corpo e profundidade (sem arte ainda)

> Brief para o agente de código. Objetivo: tirar a sensação de "raso/robótico" tornando o jogo **populado, individual e rico em sistemas** — usando código e dados, **sem assets de arte** (a passada de arte é uma fase futura, decisão do dono do projeto).
>
> Direção do dono: aprofundar conteúdo antes da arte. Focar em **profundidade dos personagens**, **sistemas de recurso mais ricos** e **mais gente/escala**. O visual continua "flat" por enquanto — a meta aqui é *conteúdo*, não beleza.

## A regra que protege o projeto (leia com atenção)

Aumentar a escala **muda o balanceamento validado**. O loop foi calibrado para 10 moradores / 3 setores / 14 turnos (ver `docs/02_GDD` §15). Ao mudar esses números, **os valores de `balance.gd` precisam ser re-encontrados** — não chutados.

Portanto, o coração desta fase é o **método**, não o palpite:
- **Preservar os PRINCÍPIOS** do GDD §15 (atenção escassa; verdade irreprimível e que escala; remoção com custo que acumula; recursos e verdade como um só problema).
- **Re-medir os NÚMEROS** com uma ferramenta de simulação em massa (Parte A), até a *forma da dificuldade* voltar ao alvo do GDD §15.4:
  - ignorar a verdade → derrota quase certa;
  - uma ferramenta só (isolar/acalmar) → vencível, mas difícil (~35–65%);
  - exilar em série → funciona, porém arriscado (a cicatriz encurrala);
  - misturar ferramentas com bom timing → o caminho de mestre (mais alto).

Nada de retunar "no olho". Meça, ajuste, remeça.

Demais regras de sempre: `sim/` sem UI; determinismo via `SeededRng`; testes verdes; a UI só lê `WorldState` / chama `SimGame`.

Sugestão: **cinco commits** — 0 (save/load), A (sweep + parametrizar escala), B (personagens), C (recursos), D (corte lateral com mais andares).

---

## PARTE 0 — Corrigir Save/Load (bug atual)

Os botões Salvar/Carregar estão **sem ação**. Corrigir:
- Conectar os sinais dos botões às funções de salvar/carregar.
- Serializar o `WorldState` completo (incl. `residents` com traços/vínculos e o **estado do `SeededRng`**) em `user://save_1.json`, com `save_version`.
- Carregar reconstrói o estado e a UI.
- **Teste de round-trip** (em `tools/run_tests.gd`): salvar → carregar → estado idêntico; avançar N turnos após carregar == avançar sem ter salvado (mesma seed).
- Validar manualmente: salvar, fechar o jogo, reabrir, carregar, continuar.

---

## PARTE A — Escala parametrizável + ferramenta de balanceamento

1. **Parametrizar a escala** em `sim/balance.gd`: `POP_SIZE`, número e tipos de setor, `MAX_TURN` como constantes já usadas por todo o `sim/`. Nada de números fixos espalhados. A geração de população/postos deve derivar dessas constantes.

2. **Ferramenta de sweep** — `tools/balance_sweep.gd` (headless), reproduzindo o método usado no protótipo:
   - Joga **N partidas** (ex.: 1000+) com várias **estratégias automáticas**: "ignora a verdade", "só isola", "só acalma", "exila em série", "misto".
   - Usa `SeededRng` com seeds variadas.
   - Imprime a **taxa de vitória** de cada estratégia.
   - Rodar com `godot --headless --script res://tools/balance_sweep.gd`.

3. **Re-calibrar** `balance.gd` para a nova escala usando o sweep, até bater a forma-alvo do GDD §15.4. Documentar no topo do `balance.gd` a escala para a qual os números valem.

4. **Escala-alvo do slice (limite — não estourar):** ~**24 moradores**, ~**6–8 setores** distribuídos nos estratos, turnos ajustados conforme o sweep indicar. Não pular para centenas de pessoas / 144 andares agora — a fantasia grande vem depois; aqui o objetivo é "populado o suficiente para não parecer vazio", mantendo o jogo shippável e balanceável.

> Este sweep é reutilizável para sempre: qualquer mudança futura de escala/números passa a ser *medida*, não adivinhada.

---

## PARTE B — Profundidade dos personagens

Fazer cada morador parecer **uma pessoa**, não uma sigla.

- **Ficha de detalhe** ao selecionar: nome completo, posto/estrato, estágio de verdade, **traços**, **vínculos** (com quem, que tipo), humor, e uma **mini-bio gerada** por template a partir de traços + posto + vínculos (data-driven; ex.: "Mecânica das Entranhas, teimosa e leal ao irmão Nael."). Nada de escrever centenas de bios à mão — modelos + dados.
- **Mais variedade de traços** e de **gatilhos de micro-história** (para o feed não repetir): rotina, atritos entre traços opostos, reações a crises de recurso, laços se formando.
- **Mostrar traço/vínculo na coluna do Poço** (um ícone/inicial na célula, ou tooltip), para o jogador reconhecer as pessoas sem abrir a ficha.
- Manter os **modificadores mecânicos de traço neutros por padrão** (como na Fase 3) até uma passada de balanceamento dedicada via sweep.

Meta (playtest): o jogador deve conseguir **apontar 2–3 moradores que "conhece"** depois de uma partida.

---

## PARTE C — Sistemas de recurso mais ricos

Tirar a sensação de "3 barrinhas abstratas" — dar **amplitude de gestão** (o que o dono ama em Stardew) e **tangibilidade**.

- **Novos recursos** (escolher 1–2 para começar, ver GDD §4): ex. **Água** e **Peças/Manutenção**, cada um com fonte (setor) e consumo. Adicionar como dados, integrar ao turno, re-balancear via sweep.
- **Upgrades de setor:** permitir investir (ação/recurso) para melhorar a produção de um setor — dá progressão e escolhas de prioridade ao longo da partida.
- **Produção visível/tangível:** a ficha do setor mostra a *conta* (quantos trabalhadores × rendimento − consumo, penalidade da suspeita), para o jogador entender de onde vem o número, não só vê-lo mudar.
- **Cadeias:** deixar explícito no modelo e na UI que energia alimenta os outros setores (sem energia, produção cai) — já existe na lógica; torná-lo legível.

Tudo isso muda o balanceamento → **re-rodar o sweep** e reafinar até a forma-alvo voltar.

---

## PARTE D — Corte lateral com mais andares

Com ~6–8 setores, a coluna do Poço fica mais alta e mais parecida com um abrigo de verdade.

- Suportar **N andares** (rolagem ou virtualização se necessário), agrupados nos estratos (Coroa / Meios / Entranhas), vários setores por estrato.
- Manter a legibilidade do docs/05: estado por cor, andar em crise tinge de vermelho, quem "sabe" salta.
- (Opcional) a escada/eixo vertical ligando os andares para reforçar a profundidade.

---

## Testes a adicionar

1. **Save/Load round-trip** (Parte 0).
2. **Sweep roda** e produz a forma-alvo: ex., "ignora a verdade" com vitória < 15%; estratégias ativas numa faixa saudável (não 0%, não 100%).
3. **Escala determinística:** mesma seed → mesma população/postos/vínculos, em qualquer `POP_SIZE`.
4. **Novos recursos** entram no cálculo de fim (zerar Água/Peças tem consequência definida).
5. **Neutralidade dos traços** (modificadores em 0 não alteram a forma da dificuldade).

## Critérios de aceite

- Save/Load funciona de verdade (round-trip + teste manual).
- A tela mostra um Poço **mais alto e povoado** (~24 moradores, ~6–8 setores) que **não parece vazio nem robótico**.
- Selecionar um morador abre uma **ficha que faz dele uma pessoa**.
- Há **mais de 3 recursos** e alguma forma de **investir/melhorar** setores.
- O sweep confirma que a **forma da dificuldade** do GDD §15.4 foi preservada na nova escala; todos os testes verdes.
- Print de uma partida com o Poço povoado e uma ficha de personagem aberta.

## Fora de escopo (importante)

- **Arte real / atmosfera visual** — é a próxima fase, por decisão do dono. Aqui o visual segue flat.
- Mecânicas de atos futuros (revelação/Ato II, escavação, drones, modo Núcleo).
- Estourar a escala para centenas de moradores / 144 andares. Ficar no limite da Parte A.

## Aviso sobre escopo

Esta fase é onde o projeto pode inchar. O guarda-corpo é a Parte A: **toda mudança de escala/número é medida pelo sweep e comparada à forma-alvo**. Se algo não couber no orçamento de tempo, corte conteúdo (menos recursos novos, menos setores) — nunca corte a re-validação.
