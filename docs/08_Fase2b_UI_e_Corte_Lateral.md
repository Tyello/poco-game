# 08 · FASE 2b — Passe de legibilidade + Corte lateral

> Brief de implementação para o agente de código. Objetivo: dar à UI a **identidade visual** do jogo (o abrigo em corte lateral) e melhorar a **legibilidade**, sem tocar na lógica.
>
> Referência de direção: `docs/05_Direcao_Arte_Audio.md` — lema **"Frostpunk na alma, Mini Metro na leitura"**. Comportamento de referência: `docs/Prototipo_Teste_Loop_v5.html`.

## Regras que continuam valendo (não quebrar)

- **Não tocar em `sim/`** nem retunar `sim/balance.gd`. A UI apenas LÊ o `WorldState` e CHAMA métodos do `SimGame`.
- Manter o smoke test headless passando (`tools/run_tests.gd` continua verde).
- Ainda **sem assets de arte** — tudo com `Control`/`Panel`/retângulos coloridos. Estabelecer a *linguagem espacial* primeiro; arte real vem depois.
- 2D, plano, escuro. Sem gradientes/sombras decorativas. Silhueta e cor a serviço da leitura.

Sugestão: fazer em **dois commits** — primeiro o Parte A (legibilidade), depois a Parte B (corte lateral), para revisão incremental.

---

## PARTE A — Passe de legibilidade (rápido, alto valor)

1. **Medidores como barras, todos iguais.** Suspeita e Rebelião hoje são texto puro. Transformar em **barras horizontais coloridas** com o mesmo tratamento dos recursos (rótulo + número + barra 0–100). Recursos e sociais lado a lado num painel de HUD coeso.

2. **Cor por limiar, consistente em tudo.**
   - Recursos (quanto mais alto melhor): >50 verde, 25–50 âmbar, <25 vermelho.
   - Suspeita e Rebelião (quanto mais alto pior): <35 verde, 35–60 âmbar, >60 vermelho.
   - Um medidor em crise deve **alarmar** (vermelho forte; opcional: piscar sutil).

3. **Piso de revolta visível.** Na barra da Rebelião, desenhar uma **marca vertical** na posição do `martyr_floor` (as cicatrizes de exílio), como no protótipo. Rótulo curto "piso: N".

4. **Peso da decisão.** O botão **Exilar** deve parecer perigoso: vermelho/borda vermelha, visualmente distinto de **Isolar** (secundário, neutro). Botões desabilitam quando `attention == 0`.

5. **Atenção clara.** Mostrar as 3 ações como **3 pontos/pips** que se apagam conforme gasta, além do número.

6. **Alerta da verdade.** Quando houver morador(es) no estado `sabe`, mostrar uma faixa de alerta ("N moradores sabem — aja"), como no protótipo. Estado calmo quando ninguém sabe.

7. **Hierarquia e espaço.** Agrupar em blocos/painéis com respiro; usar o espaço vazio; título de seção discreto. Nada de tudo espremido num canto.

---

## PARTE B — Corte lateral (a identidade do jogo)

Substituir a **lista** de moradores pela imagem que define o jogo: o Poço como **coluna vertical de andares empilhados**, visto em seção (o "arranha-céu invertido"). Ver docs/05 e docs/03 (léxico dos estratos).

### Mapeamento dos 3 sistemas do slice para os estratos

Empilhar de cima para baixo (a profundidade é destino social):

| Posição | Estrato | Conteúdo no slice |
|---|---|---|
| Topo | **A Coroa** | Faixa fina de "administração/vista": aqui ficam o alerta da verdade e a última linha do registro. Sem sistema de recurso. |
| Meio-alto | **Os Meios** | Setor **Comida** (fazendas) |
| Meio | **Os Meios** | Setor **Ar** (filtragem) |
| Fundo | **As Entranhas** | Setor **Energia** (gerador) — ponto único de falha |

Cada estrato com um leve tom-assinatura (Coroa azul-frio, Meios verde, Entranhas âmbar-quente), discreto, só para orientar.

### O que cada andar-setor mostra

- Nome do setor + **barra do recurso** correspondente (cor por limiar) + **nº de trabalhadores ativos** e o `net_delta/turno`.
- Os **moradores daquele posto** representados como **células/figuras** dentro do andar (retângulos por enquanto), coloridas pelo estágio de verdade: tranquilo (neutro/verde), desconfiado (âmbar), **sabe (vermelho/roxo, destacado)**; isolado com marca distinta.
- O sobressalente (sem posto) num pequeno slot lateral ("reserva").
- Um andar-setor em crise (recurso baixo) **tinge de vermelho** e chama atenção.

### Interação

- **Clicar num morador** (célula no andar) seleciona e abre o painel de ação contextual (Isolar/Exilar, ou Reintegrar/Exilar se isolado) — mesma lógica de hoje, só reancorada na coluna.
- HUD (medidores + botões globais Reparo/Acalmar + Avançar turno) fica numa **barra lateral ou superior**; a **coluna do Poço é o centro** da tela.
- A escada/eixo central pode ser sugerida por uma linha/tira vertical ligando os andares (reforça o "vertical").

### Legibilidade (teste de docs/05)

- Se a tela fosse quase preta, todo texto e estado seguem legíveis?
- Um andar em crise ou um morador que "sabe" é identificável em <1s, sem clicar?
- Cor saturada só onde **codifica informação** (estado), não decoração.

---

## Critérios de aceite (QA ao final)

1. `tools/run_tests.gd` continua verde; `sim/` intacto; `balance.gd` não retunado.
2. A tela agora mostra o Poço como **coluna vertical de andares**, não uma lista.
3. Suspeita e Rebelião são barras coloridas; a Rebelião mostra a marca do piso.
4. Exilar é visivelmente perigoso; ações desabilitam sem atenção.
5. Fidelidade de estado preservada: isolar mantém a produção (sobressalente cobre), exilar sobe o piso — visível na barra.
6. Uma partida completa é jogável do turno 1 ao fim, com a tela de fim intacta.
7. Commitar (Parte A e Parte B, de preferência separadas) e me mostrar um print de uma partida em andamento.

## Fora de escopo agora

Assets de arte finais, animações elaboradas, som. E nada de mecânicas de atos futuros (escavação, drones, modo Núcleo). Isto é só **forma e leitura** sobre a lógica já pronta.
