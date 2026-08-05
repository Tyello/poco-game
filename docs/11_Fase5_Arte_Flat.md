# 11 · FASE 5 — Arte de verdade (passada flat, em código)

> Brief para o agente de código. Objetivo: tirar a "cara de debug" e dar ao jogo um **visual coeso e intencional**, minimalista mas caprichado — só com código (formas, cor, tipografia, ícones), sem assets ilustrados. Espírito do `docs/05`: **"Frostpunk na alma, Mini Metro na leitura"**.
>
> Referências de qualidade a mirar: Mini Metro, Reigns, a UI do Frostpunk, Papers Please. Regra de ouro: **legibilidade num relance acima de tudo**; a beleza vem da restrição, hierarquia e consistência — não de enfeite.

## Regras (não quebrar)

- **Sem assets ilustrados/comissionados.** Permitido: formas via `_draw()`/`StyleBoxFlat`, **fontes** e **conjuntos de ícones** com **licença livre** (OFL/MIT/ISC), baixados e **incluídos no repositório** com o devido crédito. Nada de imagens de terceiros sem licença clara.
- **Não tocar em `sim/`** nem em `sim/balance.gd`. Isto é 100% apresentação. A UI só lê `WorldState`.
- **Testes verdes.** Nenhuma mudança de lógica; nenhum teste de simulação deve quebrar.
- **Legibilidade é o teto, não o piso.** Passar no checklist do docs/05 (final deste doc) é critério de aceite.
- Pré-requisito: o **commit de limpeza** (barras que escalam além de 100, Peças, bio, toast de save) já deve estar aplicado. Se não estiver, incorporar aqui.

Sugestão: **cinco commits** — A (sistema visual), B (o Poço como lugar), C (HUD/medidores), D (ficha-dossiê), E (feedback/micro-animação).

---

## PARTE A — Sistema visual (a fundação)

Centralizar o estilo, do mesmo jeito que `balance.gd` centraliza os números. Nada de cores/margens mágicas espalhadas.

- **Paleta em tokens** (`ui/palette.gd` ou um `Theme`): base escura e dessaturada (ferro, grafite), e **acentos saturados reservados para significado** (verde=ok, âmbar=atenção, vermelho=crise; um tom próprio para suspeita/verdade). Tons-assinatura discretos por estrato (Coroa azul-frio, Meios verde, Entranhas âmbar-quente).
- **Tema Godot** (`ui/theme.tres`): estilos consistentes de painel/card (`StyleBoxFlat` com cantos, borda-hairline, preenchimento), botões (normal/hover/press/disabled), barras, rótulos. Todo `Control` herda daqui.
- **Tipografia:** incluir **uma fonte de licença livre** (ex.: IBM Plex Sans/Mono, Inter ou Space Grotesk — todas OFL). Uma família para títulos/rótulos, mono opcional para números. Dois pesos, hierarquia clara (título > rótulo > corpo). Tamanho mínimo legível.
- **Ícones:** incluir um **set com licença livre** (ex.: Lucide — ISC, ou Tabler — MIT) para setores e estados (engrenagem=gerador, folha=fazenda, gota=reservatório, filtro=filtragem, etc.). Importar como fonte de ícones ou SVGs.
- **Grid e ritmo:** espaçamentos consistentes (múltiplos de uma unidade base), alinhamento, respiro. O layout atual tem espaço mal distribuído — reorganizar com hierarquia.

---

## PARTE B — O Poço como um lugar (não caixas empilhadas)

O corte lateral tem que **parecer uma estrutura**. Sem ilustração, usando composição e `_draw()`:

- **Moldura do poço + eixo central:** desenhar a "casca" do abrigo e a **escada/espinha vertical** ligando os andares — é o que dá a sensação de profundidade e de "arranha-céu invertido".
- **Andares como painéis desenhados:** cabeçalho do setor com **ícone** + nome, tom-assinatura do estrato refinado (sutil, não berrante), separadores hairline, leve indicação de profundidade (borda interna). Nada de retângulo chapado.
- **Moradores como fichas limpas ("chips"):** um monograma/silhueta simples num círculo, **cor pelo estágio de verdade** (tranquilo/desconfiado/**sabe**), com micro-indicadores de **vínculo** (o coração já existe) e **traço** (ícone pequeno). Estado de seleção e hover claros.
- **Crise que grita:** um andar com recurso baixo recebe tratamento de **alarme** inequívoco (borda/tinta vermelha, talvez pulso sutil) — identificável em <1s.
- **Reserva** e **Coroa** com identidade própria (a Coroa é a "vitrine da mentira": o alerta da verdade e o topo do diário moram nela).

---

## PARTE C — HUD e medidores

- **Barra de ações** reorganizada como uma toolbar limpa (ícone + rótulo), com os botões globais (reparos, acalmar, salvar, carregar) agrupados de forma legível. Atenção como pips claros (os 3–4 pontos) + número.
- **Medidores polidos e consistentes:** recursos e sociais com o mesmo tratamento — rótulo, número, barra que **escala corretamente** (inclusive acima de 100), **cor por limiar**, e a **marca do piso** na Rebelião. Alinhados numa grade, agrupados (Recursos | Sociedade).
- **Diário** estilizado como um feed legível (marcadores de turno, hierarquia entre micro-história humana e log mecânico, se ambos existirem).

---

## PARTE D — Ficha de personagem (o dossiê)

Transformar o painel de detalhe num **cartão de identidade** que faça a pessoa existir:

- Cabeçalho com **monograma/silhueta** num círculo (cor pelo estado), nome, posto + estrato com ícone.
- **Traços como chips** (pílulas), **vínculos** como links/nomes destacados, **humor** com um indicador.
- **Bio** num bloco de leitura confortável.
- Botões de ação (Isolar/Exilar/Reintegrar) com peso visual — **Exilar perigoso** (vermelho), distinto do Isolar (secundário).

---

## PARTE E — Feedback e micro-animação (contido)

Restrição é a regra (docs/05): animação econômica e proposital.

- **Estados de interação:** hover, seleção, press de botão, disabled — todos visíveis e consistentes.
- **Toast de sistema:** "Jogo salvo" / "Jogo carregado" e afins, discretos, some sozinho.
- **Transições sutis:** barras que fazem *tween* ao mudar; **pulso de crise** num andar em apuros; uma transição leve ao Avançar turno para o olho acompanhar o que mudou.
- Nada de exageros, brilhos ou animação que atrapalhe a leitura.

---

## Critérios de aceite (checklist de legibilidade do docs/05)

1. Se a tela fosse quase preta, **todo texto e estado seguem legíveis**?
2. Um **andar em crise** ou um **morador que "sabe"** é identificável em **<1s**, sem clicar?
3. Cor saturada aparece **só onde codifica informação** (estado), nunca como decoração?
4. A tela **parece intencional**, um jogo — não uma ferramenta de debug?
5. A **ficha de personagem** faz o morador parecer uma pessoa?
6. Estilo **consistente** entre todas as áreas (mesmos tokens, fontes, espaçamentos)?
7. Fontes/ícones incluídos têm **licença livre** e estão creditados no repositório?
8. `sim/` intacto, `balance.gd` intacto, **testes verdes**.
9. Print de uma partida (Poço + ficha aberta + um andar em crise) para revisão.

## Fora de escopo (para uma passada futura)

- **Personagens ilustrados / rostos reais**, arte de cenário desenhada, atmosfera pintada — isso é a próxima camada, com assets/IA ou artista, por cima desta base.
- Som e música.
- Qualquer mecânica nova (revelação/Ato II, escavação, drones, modo Núcleo).

## Espírito

Não é para ficar "AAA" — é para ficar **coeso, limpo e claramente um jogo**, do jeito que Mini Metro e Reigns são lindos sendo minimalistas. A base flat feita com capricho vira a fundação sobre a qual, no futuro, a ilustração entra sem retrabalho.
