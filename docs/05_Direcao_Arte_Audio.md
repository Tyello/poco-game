# 05 · DIREÇÃO DE ARTE E ÁUDIO — "O Poço"

> A tradução visual e sonora dos pilares. A regra que rege tudo: **profundidade emergente, superfície legível.**

---

## 1. Pilar visual

**Frostpunk na alma, Mini Metro na leitura.** O mundo é sombrio, industrial e opressivo, mas a *interface* que o comunica é limpa, plana e imediata. O jogador deve, num único olhar para a coluna de andares, saber onde está o problema — sem caçar informação. Toda beleza serve à clareza; nada de ruído decorativo que atrapalhe a leitura de estado.

**Três adjetivos-guia:** claustrofóbico, industrial, legível.

## 2. Perspectiva e composição

- **Corte lateral 2D** do Poço: uma seção vertical, tipo formigueiro/casa de bonecas.
- Composição em **coluna central** (a torre) com painéis de UI nas laterais.
- A **verticalidade** é enfatizada: a tela sugere que há muito mais acima e abaixo do que cabe; a escada em espiral é o eixo visual e simbólico.
- Escala humana visível: silhuetas de moradores dão vida e senso de lotação, mas sem exigir animação cara (ver §6).

## 3. Estilo de arte

Recomenda-se um estilo que uma equipe pequena sustente e que priorize legibilidade:

- **Vetorial/flat com textura sutil** ou **pixel art limpa de média resolução** — decisão a fechar no protótipo, testando qual comunica estado mais rápido. Preferência inicial: **flat/vetorial** pela clareza de silhueta e facilidade de recolorir por estado.
- **Silhuetas fortes** para setores e moradores: reconhecíveis em miniatura.
- **Menos é mais:** cada setor tem 1–2 elementos icônicos que o identificam (o gerador, a fazenda, o filtro), não cenários detalhados.
- Detalhe e "sujeira" (ferrugem, cabos, manchas) entram como **camada de atmosfera**, nunca competindo com os indicadores de estado.

## 4. Paleta

Paleta base **escura e dessaturada** (o mundo), com **acentos saturados reservados para significado** (o estado):

- **Ambiente:** cinzas industriais, ferro, âmbar de luz racionada, verde-doente das fazendas.
- **Estratos:** cada estrato tem um tom-assinatura discreto para orientação espacial — Coroa (azul-frio/luz), Meios (verde/orgânico), Entranhas (âmbar-quente/fogo do gerador).
- **Semântica de estado (saturada, usada com parcimônia):** verde = ok, âmbar = atenção, vermelho = crise. Suspeita/rebelião podem ter um acento próprio (ex.: um roxo/magenta frio) para não confundir com recursos físicos.
- **Regra:** cor saturada = informação. Se está colorido e vibrante, quer dizer algo. O resto do quadro é contido.

## 5. Interface (a estrela do show)

A UI **é** o jogo; merece o maior cuidado.

- **Legibilidade num relance (lição Mini Metro/Motorways):** a coluna comunica estado por cor/ícone sem clique. Um andar em crise "grita" (pulsa, muda de cor).
- **Hierarquia:** visão macro sempre limpa; **detalhe sob demanda** ao clicar um andar/morador.
- **Medidores:** poucos, grandes, sempre visíveis (recursos físicos + moral/suspeita/rebelião). Números arredondados; tendência (subindo/descendo) indicada.
- **Painel de decisão:** cena clara e consistente (estilo Reigns/Frostpunk) com opções e **consequências previsíveis** destacadas. A decisão moral precisa *parecer* pesada.
- **Micro-histórias:** um log/feed humano ("Marta parou de comer…") para gerar apego — texto é parte da arte.
- **Sem sopa de ícones:** limitar o número de elementos ativos na tela; agrupar; usar espaço em branco (mesmo num tema escuro).
- **Tipografia:** uma família legível e de caráter industrial para títulos; corpo altamente legível. Duas pesos, hierarquia forte.

## 6. Animação

- **Econômica e proposital.** Priorizar: transições de estado (um setor pegando fogo, luzes apagando no blackout), movimento sutil dos moradores (idle, caminhar pela escada), e o "peso" das decisões.
- Evitar animação de personagem custosa; silhuetas com poucos frames ou tweening bastam.
- **Feedback de crise** é a animação mais importante: quando algo dá errado, a tela precisa comunicar urgência de imediato.

## 7. Direção de áudio

O som carrega metade da opressão. Referências de mood: *Frostpunk*, *This War of Mine*, *Alien: Isolation* (tensão de espaço fechado).

- **Ambiência industrial constante:** o zumbido grave do gerador (mais forte nas Entranhas), gotejar, ventilação, o ranger da escada. O silo "respira".
- **Áudio diegético por profundidade:** descer aproxima o gerador; subir traz o murmúrio do refeitório. Ajuda na orientação vertical.
- **Música minimalista e escassa:** longos silêncios; a trilha entra em momentos-chave (uma revelação, uma Saída, o clímax da fuga). Cordas frias, drones graves, piano solitário.
- **Estados sonoros:** camadas de tensão que sobem com suspeita/rebelião (o ambiente fica mais agudo, dissonante).
- **Momentos de assinatura sonora:** a Saída (o assobio do ar/argônio, depois o silêncio), o blackout (tudo morre, só resta o coração batendo), o primeiro voo de drone (um raro sopro de esperança na trilha).
- **Voz:** provavelmente sem dublagem completa (custo); considerar murmúrios/emotes não-verbais para os moradores e talvez rádio processado nas comunicações entre Poços.

## 8. Diretrizes de marca / identidade

- **Logotipo/título:** sugerir verticalidade e profundidade; sensação de peso e reclusão.
- **Key art:** o corte do Poço visto de longe, minúsculas luzes em andares, a escuridão acima e abaixo — a imagem que vende o conceito em um quadro.
- **Coerência com a UI:** a identidade visual do marketing deve nascer da mesma linguagem plana/legível do jogo, para não frustrar expectativa.

## 9. Referências visuais/sonoras (moodboard textual)

Frostpunk (opressão + UI de dilema) · This War of Mine (corte lateral, melancolia, silhuetas) · Sheltered (abrigo em seção) · Oxygen Not Included (setores funcionais legíveis) · Mini Metro/Motorways (clareza abstrata) · Metro/Fallout (estética de abrigo industrial) · Alien: Isolation (som de espaço fechado).

## 10. Checklist de legibilidade (teste para todo asset de UI)

- Se a tela fosse quase preta, todo texto e estado ainda seriam legíveis?
- Um andar em crise é identificável em menos de 1 segundo, sem clicar?
- A cor saturada nesta tela está **codificando informação** ou só decorando? (Se decora, remover.)
- A decisão moral na tela *parece* pesada, ou parece um menu qualquer?
