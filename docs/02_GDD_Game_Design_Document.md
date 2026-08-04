# 02 · GAME DESIGN DOCUMENT — "O Poço"

> Referência central de design. Documento vivo: espera-se que mude com os testes do vertical slice.

---

## 1. Visão e pilares

**Visão:** um jogo de gestão e sobrevivência em que administrar um abrigo vertical é, no fundo, administrar uma mentira. O jogador equilibra recursos físicos, moral coletiva e o vazamento da verdade, distribuindo uma quantidade sempre insuficiente de atenção entre 144 andares.

**Pilares (toda decisão de design deve servir a pelo menos um):**

1. **A verdade é um recurso perigoso.** Conhecimento vaza, se propaga e desestabiliza; contê-lo custa moral e lealdade.
2. **Escassez de atenção.** O gargalo não é só "ter recursos", é "ter turnos/ações para cuidar de tudo".
3. **Gente com nome.** Indivíduos com traços, necessidades e vínculos; perdas têm rosto.
4. **Legibilidade sobre profundidade emergente.** Sistemas simples de ler que se combinam em histórias complexas.
5. **Moral cinza.** Não há botão "do bem"; há trocas. O antagonismo é sistêmico, não caricato.

**Anti-pilares (o que o jogo NÃO é):** não é um shooter; não é um city-builder relaxante e aberto; não é um jogo de otimização sem consequência humana; não entrega a verdade do mundo de graça no início.

---

## 2. Fantasia e ponto de vista

O jogador é **o Administrador** do Poço. Câmera em **corte lateral 2D**: a coluna de andares é visível de uma vez, como uma seção de formigueiro. O jogador não controla um avatar — controla um sistema, emitindo ordens, alocando pessoas e tomando decisões. A verticalidade é a mecânica-mãe: distância = tempo + custo + política.

---

## 3. Loop central

### 3.1 Loop de turno (momento a momento)
O tempo avança em **turnos** (a unidade diegética; ver Bíblia — as "Vigílias"). A cada turno o jogador tem **pontos de atenção/ação limitados** e deve escolher onde gastá-los:

1. **Avaliar estado** — ler medidores (recursos, moral, suspeita, rebelião) e alertas por andar.
2. **Alocar** — designar moradores a postos (fazenda, gerador, filtragem, oficina, segurança, educação), mover cargas pela coluna.
3. **Investir** — melhorar/reparar/construir setores (amplitude estilo Stardew: sempre há algo a evoluir).
4. **Decidir** — resolver eventos e dilemas (estilo Reigns/Frostpunk) que surgem no turno.
5. **Avançar turno** — os sistemas processam; consequências e novas crises emergem.

### 3.2 Loop de médio prazo (a campanha)
Turnos se agrupam em **capítulos** pontuados por **revelações** que mudam as regras (ver §7). O jogador acumula melhorias, história e segredos.

### 3.3 Loop de meta (entre runs)
Cada abrigo eventualmente cai (colapso físico ou social) ou é evacuado. O **Legado** preservado (sementes, conhecimento, sobreviventes) alimenta a próxima run — roguelite diegético (ver §8).

---

## 4. Sistemas de recursos (o anel físico)

Recursos são **localizados** — cada um vive em andares específicos, então crises são lugares a alcançar, não só números a corrigir.

| Recurso | Fonte (andar) | Consumo | Falha significa |
|---|---|---|---|
| **Ar / Filtragem** | Filtros (meio) | População | Asfixia gradual; morte por andar |
| **Energia** | Gerador (fundo) | Tudo | Blackout; sistemas param; pânico |
| **Comida** | Fazendas hidropônicas (meio) | População | Fome; queda de moral e saúde |
| **Água** | Bombas/tratamento (fundo) | População, fazendas | Racionamento; doença |
| **Peças / Manutenção** | Oficinas + reciclagem | Reparos | Sistemas degradam e quebram |
| **Remédios** | Clínica (meio) | Doentes/feridos | Epidemias, mortes |

Princípios: tudo **degrada** com o tempo e exige mão de obra; o gerador é **ponto único de falha** deliberado; superpopulação pressiona ar e comida, subpopulação falta mão de obra (a demografia é recurso).

---

## 5. Sistema humano (o coração)

### 5.1 Moradores como indivíduos
Cada morador tem: **nome**, **casta/andar de origem**, **traços** (ex.: corajoso, cético, devoto, resmungão), **necessidades** (comida, descanso, propósito, segurança), **relações** (família, amizades, rivalidades) e **estado psicológico** (moral, medo, trauma). O jogo deve gerar **micro-histórias** legíveis ("Marta, da Forja, parou de comer desde que o irmão saiu").

### 5.2 Castas e verticalidade social
Três estratos ligados ao andar (ver Bíblia): **Coroa** (topo/privilégio/administração), **Meios** (produção civil), **Entranhas** (mecânica/trabalho pesado). Fricção entre estratos é uma fonte estrutural de conflito. Mobilidade entre andares é literal e política (exige "passe"/permissão).

### 5.3 Medidores sociais
- **Moral** (por estrato e global): produtividade e estabilidade.
- **Suspeita**: quanto a população desconfia da versão oficial da realidade. Sobe com inconsistências, acidentes, censura mal feita.
- **Rebelião**: alimentada por suspeita + injustiça acumulada. Ao estourar, vira crise armada (custosa para todos — fogo, dano ao gerador, mortes).

Regra-chave: **reprimir baixa a suspeita hoje e sobe a rebelião amanhã.** É a tensão de gestão central.

---

## 6. Sistema da verdade (o diferencial)

Existe uma **verdade oculta** sobre o mundo (revelada em camadas, §7). Cidadãos podem "ver" — por acidente, curiosidade ou acesso indevido a informação. Um morador que sabe demais é um **vetor de contaminação** (a verdade se espalha por vínculos sociais, como doença).

Ferramentas do jogador para gerir isso (todas com custo):
- **Censura / controle de informação** — apaga registros, restringe acesso. Baixa suspeita local, mas se descoberta, dispara.
- **Propaganda / decretos** (à la Tropico) — molda a crença coletiva; consome atenção e credibilidade.
- **"Promoção" isoladora** — afasta quem sabe demais para postos isolados.
- **A Saída (exílio ritual)** — remove definitivamente o vetor; forte impacto moral, pode virar mártir.
- **Revelar** — contar a verdade a alguém/todos: alívio de curto prazo, caos de longo prazo.

Apresentação: dilemas da verdade podem usar um **formato de decisão restrita estilo Reigns** (2–4 opções, consequências claras nos medidores), o que mantém a legibilidade.

---

## 7. Progressão por revelação (a espinha dramática)

A campanha avança por **camadas de verdade** que reconfiguram o jogo. Espelham a trilogia-fonte, mas o jogador as descobre por jogabilidade:

- **Camada 1:** o exterior é tóxico e a Saída é morte.
- **Camada 2:** o Véu mente — a imagem do exterior é falsa; as pessoas "saem" por esperança fabricada.
- **Camada 3:** existe um controle acima de você que edita a história e vigia tudo.
- **Camada 4:** há **outros Poços**, isolados; e um plano secreto — só um foi feito para sobreviver.
- **Camada 5:** o exterior é um **gradiente** (o Cerco) mantido artificialmente; além dele, o mundo se recupera. Escapar é possível.

Cada revelação **muda a meta e destrava verbos** (ver §9).

---

## 8. Estrutura de partida e meta-progressão

### 8.1 As Vigílias (runs)
O tempo é organizado em **Vigílias** — períodos de administração ativa separados por saltos (o Administrador "descansa" e retoma depois). Cada Vigília é uma **run** com objetivos; o estado do mundo persiste entre elas. Isso dá a estrutura roguelite de FTL/Into the Breach de forma diegética.

### 8.2 O Legado (New Game+)
Ao fim de uma run (queda ou evacuação), o que foi preservado — sementes, conhecimento técnico, sobreviventes-chave — forma o **Legado**, que dá vantagens/opções na próxima. Falhar ensina o meta-mundo; o jogador fica mais forte em conhecimento, não em números triviais.

### 8.3 Dois modos de jogo (mesmo mundo, lados opostos)
- **Modo Poço (padrão):** você administra um abrigo comum. O meta-segredo é o mistério profundo a descobrir. Fantasia: sobreviver e, por fim, escapar.
- **Modo Núcleo (avançado/desbloqueável):** você administra o **controle central**, operando em Vigílias criogênicas ao longo de séculos, monitorando vários Poços — e, no clímax da Diretriz, **decidindo qual sobrevive e qual é desligado**. Fantasia: o carrasco que guarda a verdade. Um botão de peso moral Frostpunk-tier.

---

## 9. Verbos por ato

| Ato | Fantasia | Verbos-núcleo | Verbos destravados |
|---|---|---|---|
| **I — Às cegas** | Sobreviver | Alocar, reparar, decidir, conter suspeita | — |
| **II — O sistema** | Entender | + investigar, censurar, contatar por rádio | Comunicação entre Poços |
| **III — A fuga** | Escapar | + escavar (conectar Poços), reconhecer o exterior (drones), evacuar | Fog-of-war externo; gradiente do Cerco; empurrão final |

**Escavação:** abrir túneis entre abrigos — arriscado (inundação, colapso), junta populações com culturas diferentes (novo atrito social).
**Reconhecimento externo:** enviar drones/exploradores para mapear o exterior; cada ida revela um pedaço e testa "quão longe é longe demais" (o Cerco derruba o que avança demais).
**Evacuação (fim de jogo):** gastar todos os sistemas construídos numa saída única e desesperada — clímax estilo Frostpunk.

---

## 10. Condições de vitória e derrota

**Derrota:**
- **Colapso físico** — ar/energia/água/comida em zero prolongado; o abrigo morre.
- **Colapso social** — a rebelião toma o abrigo; o Administrador cai.

**Vitória (ramificada, não "limpa"):**
- **Ordem preservada** — manter o abrigo estável e a mentira intacta por gerações (final "cúmplice").
- **Fuga / verdade** — revelar a verdade e conduzir sobreviventes ao exterior (final "libertador", alto risco).
- Finais intermediários conforme quem sobrevive e o que se preserva no Legado.

Filosofia: sobrevivência longa com **finais morais**, não um "you win" asséptico. Roguelite leve: todo abrigo cai um dia; o jogador recomeça sabendo mais.

---

## 11. Economia de dificuldade

A dificuldade vem de **atenção insuficiente** e **decisões sem resposta certa**, não de números punitivos arbitrários. Alavancas de balanceamento: pontos de atenção por turno, ritmo de degradação, frequência/severidade de crises, velocidade de propagação da suspeita, custo social das ferramentas de repressão. Modos de dificuldade ajustam essas alavancas (ex.: "Narrativo", "Padrão", "Frostbite/Sobrevivência").

---

## 12. UX e interface (princípios)

- **Legibilidade num relance** (lição Mini Metro): a coluna de andares comunica estado por cor/ícone sem exigir cliques. Um andar em crise "grita" visualmente.
- **Detalhe sob demanda:** clicar um andar/morador abre o detalhe; a visão macro fica limpa.
- **Decisões como cartas/painéis** claros, com consequências previsíveis nos medidores (transparência estilo Frostpunk/Reigns).
- **Feedback humano:** micro-histórias de moradores em log/toasts para criar apego.
- **Sem sopa de ícones:** poucos sistemas visíveis por vez; hierarquia visual forte.

Ver doc 05 (Direção de Arte e Áudio) para a linguagem visual detalhada.

---

## 13. Conteúdo (escopo do jogo completo — indicativo)

- **Andares/setores:** ~144 andares agrupados em ~12–16 tipos de setor funcional.
- **Recursos:** 6 físicos + 3 sociais (moral, suspeita, rebelião).
- **Eventos/dilemas:** biblioteca de ~150–250 eventos (crises, decisões morais, micro-histórias), com pré-requisitos e ramificações.
- **Revelações:** 5 camadas de verdade.
- **Facções:** 3 estratos + facções emergentes (rebeldes, devotos da ordem, ceticos).
- **Modos:** Poço (campanha) + Núcleo (desbloqueável) + possível modo livre/endless.

Ver doc 06 para o recorte do **vertical slice** (muito menor).

---

## 14. Riscos de design (e mitigação)

- **Complexidade sufocante** → começar pequeno (vertical slice), adicionar sistemas só quando o anterior é divertido.
- **Repressão vira estratégia dominante e fria** → garantir que reprimir sempre cobre um preço social crescente e visível.
- **População vira planilha (perde o apego)** → investir cedo em nomes, traços e micro-histórias; testar se exilar "dói".
- **Revelações entregues cedo demais** → travar cada camada atrás de progresso; a camada 5 é endgame.
- **Escopo** → ver doc 06; o inimigo número um do projeto é o próprio tamanho.

---

## 15. Princípios validados no protótipo (playtest)

Antes de qualquer código no motor, o loop central foi testado num protótipo jogável de papel (HTML), em cinco iterações com playtest real. Estes princípios **não são teoria — foram testados, quebrados e corrigidos**. O vertical slice em Godot deve começar já respeitando-os.

### 15.1 Os cinco princípios que fazem o loop funcionar

1. **A escassez real é de atenção, não de recursos.** O gargalo que gera tensão é ter poucas ações por turno (no protótipo: 3), obrigando a priorizar entre cuidar de recursos e conter a verdade. Foi isso que criou o "dói escolher".

2. **A verdade tem que ser irreprimível.** Se o jogador consegue eliminar/conter a verdade de forma barata e definitiva, o jogo vira trivial ("contenha os primeiros e surfe"). A correção: uma **pressão de base que regenera E escala com o tempo** — pessoas desconfiam sozinhas, e a taxa cresce a cada turno ("a mentira envelhece"). O jogador nunca "resolve" a verdade, só administra uma maré que sobe.

3. **Toda ação de remoção precisa de custo que acumula.** Qualquer ferramenta que remova um portador da verdade de forma permanente e barata vira estratégia dominante (no teste, "exilar todo mundo" vencia 100% até isso ser corrigido). A solução: o exílio deixa uma **cicatriz permanente** (um piso de rebelião que nunca baixa). Exilar pontualmente é uma válvula; exilar em série se afoga. Isolar, por sua vez, **não é grátis**: contém, mas o isolado continua consumindo recursos e gera boatos que sobem a suspeita.

4. **Recursos e verdade têm que ser o mesmo problema.** Enquanto rodavam em paralelo, dava para vencer cuidando só de um. A unificação: **trabalhadores produzem recursos; a suspeita corta a produção de todos** (penalidade que chega a ~−50%); e remover gente (isolar/exilar) enfraquece o sistema em que ela trabalhava. Agora negligenciar a verdade estrangula a economia — ignorar a verdade passou a perder ~100% das vezes.

5. **Legibilidade vem de ações que miram alvos concretos.** Uma ação abstrata de "conter difusão" foi testada e reprovada: o jogador não via efeito e sentia que "não fazia diferença". Substituída por decisões sobre **pessoas nomeadas** com efeito claro (isolar/exilar *fulano*), a clareza apareceu. Regra: cada ação precisa de causa-e-efeito visível.

### 15.2 Formato do estado da verdade

Conhecimento é um **pipeline de três estágios** por morador: `tranquilo → desconfiado → sabe`. Só quem "sabe" contamina ativamente; "desconfiados" avançam sozinhos com o tempo. Isso dá o "quanto cada um sabe" de forma legível e cria antecipação (dá para ver a ameaça se formando).

### 15.3 Números-base que funcionaram (ponto de partida para o slice)

Valores calibrados por ~15 mil partidas automáticas + playtest. São **ponto de partida**, não lei — o motor real vai reajustar:

| Parâmetro | Valor testado |
|---|---|
| Ações por turno | 3 |
| Duração de uma partida (slice) | 14 turnos |
| População inicial | 10 (3 por sistema + 1 sobressalente) |
| Sementes de verdade iniciais | 2 |
| Recursos | 3 (ar, energia, comida), início ~60 |
| Produção por trabalhador | ~8/turno |
| Penalidade de produção pela suspeita | até ~−50% (linear com a suspeita) |
| Consumo por morador | ~2,3, subindo ~0,06/turno (escalada) |
| Pressão de base (novo desconfiado) | 5% + 1,5%/turno |
| Auto-avanço (desconfiado→sabe) | 5% + 0,8%/turno |
| Custo do exílio | rebelião +14 imediata **+ piso permanente +22** |
| Vazamento do isolado | suspeita +1,5/turno por isolado |

### 15.4 A forma de dificuldade almejada (comprovada no teste)

- **Não fazer nada → derrota quase certa** (a verdade estoura a suspeita).
- **Uma única ferramenta (só isolar, só acalmar) → vencível, mas difícil** (~35–65%).
- **Exilar em série → funciona, mas arriscado** (a cicatriz encurrala; ~70%).
- **Misturar as ferramentas com bom timing → o caminho de mestre** (mais alto).
- Uma partida perdida deve parecer **justa** e puxar o "só mais uma vez". (Confirmado em playtest.)
