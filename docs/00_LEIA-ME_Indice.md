# PROJETO "O POÇO" — Pacote de Pré-produção

> **Codinome:** O Poço · **Gênero:** Survival/management 2D em corte lateral · **Engine-alvo:** Godot 4
> **Status:** Conceito com **loop central validado em protótipo** (5 iterações de playtest) · Pronto para o vertical slice · **IP:** Original (inspirado tematicamente na trilogia *Silo* de Hugh Howey, sem usar seus nomes ou lore)

---

## O que é este pacote

Conjunto de documentos de design e produção para um jogo de gestão e sobrevivência inspirado *tematicamente* na trilogia *Silo* (Wool / Shift / Dust), reinterpretado como propriedade intelectual original. O objetivo destes documentos é permitir prototipar, pitchar e planejar o desenvolvimento.

## Índice dos documentos

| # | Documento | Para quê serve | Quem usa |
|---|---|---|---|
| 01 | **Pitch / One-pager** | Vender a ideia em uma página: visão, gancho, pilares | Todos / investidores / parceiros |
| 02 | **Game Design Document (GDD)** | A referência central de mecânicas, sistemas, loop e conteúdo | Design, programação |
| 03 | **Bíblia de Mundo e Narrativa** | O universo original: léxico, geografia, facções, arco em 3 atos | Narrativa, arte, design |
| 04 | **Documento Técnico (TDD)** | Arquitetura, engine, dados, save, riscos técnicos | Programação |
| 05 | **Direção de Arte e Áudio** | Linguagem visual, paleta, UI, som | Arte, áudio |
| 06 | **Plano de Produção / Vertical Slice** | O que construir primeiro, milestones, riscos, critério de sucesso | Produção, todos |
| 07 | **Backlog da Fase 1** | Tickets de implementação da simulação headless em Godot | Programação |
| — | **Protótipo de teste (HTML)** | Loop jogável de validação — `Prototipo_Teste_Loop_v5.html` (versão final) | Todos |

## Resumo do conceito (30 segundos)

Você administra **o Poço**, um abrigo subterrâneo vertical de 144 andares, último reduto aparente da humanidade num mundo exterior tóxico. Seu trabalho impossível é manter todos vivos, produtivos e **ignorantes** — porque a verdade sobre o mundo lá fora é perigosa. Recursos importam, mas a escassez real é de **tempo e atenção**: você nunca consegue cuidar de todos os andares ao mesmo tempo. Cada decisão moral (censurar, exilar, revelar) equilibra ordem contra rebelião. Ao longo de três atos, o jogo troca de fantasia: **sobreviver às cegas → entender o sistema → escapar dele**.

## Pilares de design (resumo)

1. **A verdade é um recurso perigoso** — informação vaza como o ar vaza; conter custa moral.
2. **Escassez de atenção, não só de recursos** — muitos sistemas, poucos turnos (herança de Stardew + Frostpunk).
3. **Gente com nome** — a população são indivíduos pelos quais você se apega (herança de Stardew + This War of Mine); por isso o exílio dói.
4. **Sistemas legíveis que geram histórias** — clareza visual minimalista (Mini Metro) sobre profundidade emergente (RimWorld/FTL).
5. **Decisão moral como mecânica** — sem vilão caricato; a ordem custa cumplicidade (Frostpunk/Reigns).

## Referências-âncora

*Frostpunk 1* (espinha dramática + sociedade que se volta contra você) · *This War of Mine* / *Sheltered* (custo humano) · *Stardew Valley* (amplitude de sistemas + gestão de tempo) · *FTL* / *Into the Breach* (runs, crises legíveis) · *Reigns* (decisão moral restrita) · *Tropico* (manipulação política/informacional) · *Mini Metro* (clareza visual).

## Nota sobre nomenclatura (IP original)

Todos os nomes próprios abaixo são **placeholders substituíveis**, criados para não usar termos da obra original:

| Conceito | Na obra original (*Silo*) | Neste projeto |
|---|---|---|
| O abrigo vertical | Silo | **o Poço** |
| Silo de controle | Silo 1 | **o Núcleo** |
| A lei sagrada do abrigo | o Pacto | **o Preceito** |
| O plano-mestre do controle | a Ordem | **a Diretriz** |
| O exílio ritual / "limpeza" | a limpeza | **a Saída** |
| A imagem falsa do exterior | o visor | **o Véu** |
| Os operadores em criogenia | turnos | **Vigias / Vigílias** |
| A faixa tóxica externa | — | **o Cerco** |
| As nanomáquinas | nanobots | **o Enxame** |
| O estoque de superfície | o Legado | **o Legado** (genérico, mantido) |

## Estado da validação

O loop central foi testado num protótipo jogável (HTML), em 5 iterações com playtest real, até bater o critério "prende ou não prende": inação leva à derrota, a dificuldade parece justa, as ações são legíveis e uma derrota puxa o "só mais uma vez". Os aprendizados estão consolidados no **GDD, seção 15 (Princípios validados no protótipo)** — inclusive os números-base que funcionaram. Conclusão: **o conceito está validado; o gargalo agora é construir, não desenhar.**

## Próximos passos sugeridos

1. Validar/renomear o léxico da IP.
2. Construir o **vertical slice** em Godot seguindo o **backlog da Fase 1 (doc 07)** — simulação headless primeiro, respeitando os princípios do GDD §15.
3. Ligar a camada visual (corte lateral) sobre o estado já testado (Fase 2 do doc 06).
