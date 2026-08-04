# 06 · PLANO DE PRODUÇÃO / VERTICAL SLICE — "O Poço"

> Como sair do papel sem estourar o escopo. O inimigo número um deste projeto é o próprio tamanho — este documento existe para contê-lo.

---

## 1. Filosofia de produção

**Prove o loop antes de construir o jogo.** Não se valida um management-survival na planilha; valida-se quando 30 minutos dele são tensos e difíceis de largar. Todo o plano abaixo serve a uma pergunta: **"prende ou não prende?"** Se a fatia mínima não prende, nenhuma quantidade de conteúdo salva — e é melhor descobrir isso em semanas do que em anos.

## 2. Critério de sucesso do vertical slice

O slice é bem-sucedido se, num playtest com estranhos:

1. O jogador entende o loop sem tutorial extenso.
2. O jogador enfrenta pelo menos uma **decisão moral difícil** e hesita.
3. O jogador sente a **escassez de atenção** (não conseguir cuidar de tudo).
4. Uma perda (um morador exilado/morto) provoca reação emocional.
5. Ao "game over", a reação mais comum é **"só mais uma vez"**.

Se 4 dos 5 acontecerem, o conceito está provado.

## 3. Escopo do vertical slice (o que ENTRA)

Deliberadamente minúsculo perto do jogo completo (ver GDD §13):

| Área | Jogo completo | Vertical slice |
|---|---|---|
| Andares | ~144 | **12–15** |
| Estratos | 3 | **2** (Meios + Entranhas) |
| Recursos físicos | 6 | **3** (energia, comida, ar) |
| Medidores sociais | 3 | **2** (moral, suspeita) |
| Moradores | centenas | **~12–20, com nome e traços** |
| Setores funcionais | 12–16 tipos | **4–5** (gerador, fazenda, filtro, oficina, alojamento) |
| Eventos/dilemas | 150–250 | **8–12** |
| Camadas de revelação | 5 | **1** (o Véu mente) |
| Modos | Poço + Núcleo | **só Poço** |

## 4. O que fica de FORA do slice (explicitamente)

Modo Núcleo; escavação entre Poços; drones/reconhecimento externo; rebelião armada completa; sistema de facções emergentes; meta-progressão do Legado; áudio final; arte final. Tudo isso é **pós-validação**. Anotar como backlog, não construir agora.

## 5. Roadmap por fases

### Fase 0 — Pré-produção (curta)
Fechar léxico da IP, decidir estilo de arte (flat vs pixel) via teste rápido de legibilidade, montar projeto Godot + Git/LFS + estrutura de pastas. **Saída:** repositório pronto e um "andar" desenhado em dois estilos para comparar.

### Fase 1 — Protótipo de simulação (headless)
Implementar `WorldState` + `SimClock` + 3 recursos + avanço de turno, com testes. Sem arte. **Saída:** a economia roda e é balanceável em texto/testes (TDD §11, passos 1).

### Fase 2 — Vista em corte jogável
Coluna de 12–15 andares lendo o estado; alocação de moradores a postos; medidores na tela. **Saída:** dá para "jogar" a gestão de recursos com feedback visual mínimo.

### Fase 3 — Camada humana + verdade
Moradores com nome/traços/vínculos; medidor de suspeita; propagação de conhecimento; 1 ciclo de revelação (o Véu) via painel de decisão data-driven. **Saída:** a primeira decisão moral difícil existe e funciona.

### Fase 4 — Conteúdo e ritmo do slice
8–12 eventos, 1 crise central (ex.: falha do gerador OU um morador que "viu"), condições de vitória/derrota do slice, save/load. **Saída:** os 30 minutos completos, começo-meio-fim.

### Fase 5 — Polimento mínimo + playtest
Áudio de tensão temporário, feedback de crise, onboarding leve. Rodar playtests contra o critério da §2 e iterar. **Saída:** veredito "prende ou não prende" com evidência.

*(Sem prazos fixos aqui: dependem de equipe/dedicação. A ordem e as saídas é que importam. Estime datas só depois de conhecer a velocidade real da equipe na Fase 1.)*

## 6. Equipe e papéis (mínimo viável)

O slice é factível com pouca gente, com papéis podendo se acumular numa ou duas pessoas:

- **Design/Programação** (essencial): monta a simulação e a UI em Godot. Núcleo do projeto.
- **Arte/UI** (essencial): linguagem visual legível, setores, moradores, ícones.
- **Narrativa/Áudio** (pode ser parcial/terceirizado): eventos, textos das micro-histórias, som de tensão.

Solo é possível (é um jogo de sistemas e UI, não de conteúdo massivo), mas uma dupla design-programador + artista acelera muito.

## 7. Métricas e instrumentação

Instrumentar o slice para os playtests: tempo até primeiro game over, causa da morte (física vs social), quantas vezes o jogador reprimiu vs revelou, em que ponto largou, e a pergunta pós-jogo "jogaria de novo?". Esses dados dizem se o loop e o balanceamento funcionam.

## 8. Riscos de produção e mitigação

| Risco | Mitigação |
|---|---|
| **Creep de escopo** (o maior) | Congelar a tabela da §3; toda ideia nova vai para backlog pós-slice |
| Perfeccionismo de arte cedo | Arte "boa o suficiente" no slice; polimento só após validar o loop |
| Balanceamento sem fim | Data-driven + testes headless; timeboxar tunagem |
| Loop não prende | É um resultado válido e barato — descobrir cedo é o objetivo, não o fracasso |
| Motivação/energia (indie) | Fases curtas com "saídas" tangíveis para manter momentum |

## 9. Depois do slice (visão macro, se validar)

1. **Fatia jogável expandida** (mais recursos, estratos, camadas 1–3 de revelação).
2. **Demo pública / Steam Next Fest** para medir interesse real e construir wishlist.
3. **Early Access** com a campanha do Ato I–II; iterar com comunidade.
4. **1.0** com Ato III (escavação, drones, fuga) e o **Modo Núcleo** como grande gancho pós-lançamento.

## 10. Regra de ouro do projeto

Uma espinha dramática, um segredo por vez, uma engine barata, uma fatia. O material de mundo é forte e a referência (Frostpunk) é comprovada; **o único jeito realista de estragar é pelo escopo.** Este plano inteiro existe para impedir isso.
