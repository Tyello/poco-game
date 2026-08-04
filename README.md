# O Poço — repositório do jogo

Jogo de **survival/management** em Godot 4 (IP original inspirada tematicamente na trilogia *Silo*). Este repositório contém o **núcleo de simulação** já implementado e testado, mais toda a documentação de design em `docs/`.

> **Você nunca usou Godot?** Sem problema. Este guia assume zero experiência. Você não precisa saber programar para colocar o projeto para rodar nem para deixar o agente de código trabalhando.

---

## O que já está pronto

- A **lógica do jogo** (a "simulação"): recursos, trabalhadores, a verdade que se espalha, suspeita e rebelião — o loop que validamos no protótipo. Está em `sim/`.
- **Testes automáticos** que provam que a lógica funciona (`tools/run_tests.gd`).
- Uma **demonstração** que joga uma partida sozinha e imprime o resultado (`tools/run_sim.gd`).
- Ainda **não há tela/visual** — isso é o próximo passo (a "Fase 2"), e é o que o agente de código vai construir.

---

## Passo 1 — Instalar o Godot (5 minutos, sem instalador)

1. Acesse **https://godotengine.org/download**.
2. Baixe o **Godot Engine 4.3** (versão "Standard", não a ".NET/C#") para o seu sistema (Windows, macOS ou Linux).
3. O download é um **.zip**. Extraia. Dentro há **um único programa** (ex.: `Godot_v4.3-stable_win64.exe`). Não precisa instalar — é só abrir esse programa. Guarde-o num lugar fácil (ex.: sua Área de Trabalho).

## Passo 2 — Abrir o projeto

1. Abra o programa do Godot. Vai aparecer um "Gerenciador de Projetos".
2. Clique em **Importar** e selecione o arquivo **`project.godot`** desta pasta.
3. Clique em **Importar e Editar**. Pronto — o projeto abriu no editor.

## Passo 3 — Rodar os testes (opcional, para confirmar que está tudo ok)

Os testes rodam pela **linha de comando** (o "Terminal" no Mac/Linux, ou o "Prompt de Comando"/"PowerShell" no Windows). Você aponta o programa do Godot para o script de testes:

**Windows** (ajuste o caminho do Godot e desta pasta):
```
"C:\caminho\para\Godot_v4.3-stable_win64.exe" --headless --path "C:\caminho\para\poco_game" --script res://tools/run_tests.gd
```

**macOS / Linux:**
```
/caminho/para/Godot --headless --path /caminho/para/poco_game --script res://tools/run_tests.gd
```

Se aparecer **"X passaram, 0 falharam"**, está tudo certo. Para ver uma partida rodando sozinha, troque `run_tests.gd` por `run_sim.gd`.

> Dica: se a linha de comando for confusa, tudo bem — você pode pedir para o agente de código (Passo 5) rodar os testes por você.

---

## Passo 4 — Colocar no GitHub (para versionar e compartilhar)

Este repositório já tem o Git iniciado com um primeiro commit. Para subir ao GitHub:

1. Crie uma conta em **https://github.com** (se ainda não tiver).
2. Crie um repositório novo, **vazio** (sem README), com o nome que quiser (ex.: `o-poco`).
3. O GitHub mostra os comandos para "enviar um repositório existente". Serão parecidos com:
```
git remote add origin https://github.com/SEU_USUARIO/o-poco.git
git branch -M main
git push -u origin main
```
Rode-os dentro desta pasta. (De novo: o agente de código pode fazer isso por você.)

---

## Passo 5 — Deixar o agente de código trabalhando

O arquivo **`CLAUDE.md`** já contém todo o contexto: o que está pronto, as regras de arquitetura, como rodar os testes e **quais são as próximas tarefas** (construir a interface visual — a Fase 2).

Aponte o agente de código para **a pasta deste repositório** e peça algo como:
> "Leia o CLAUDE.md e o docs/, rode os testes, e comece a Fase 2: a camada visual (vista em corte lateral) que lê o WorldState. Mantenha a regra de não acoplar a simulação à UI."

O agente vai ler o guia, entender o estado do projeto e seguir o backlog.

---

## Estrutura da pasta

```
poco_game/
├─ project.godot        # o projeto Godot (abra este arquivo no editor)
├─ CLAUDE.md            # guia para o agente de código (leia se for programar)
├─ README.md            # este arquivo
├─ sim/                 # a lógica do jogo (sem interface) — o núcleo testado
├─ tools/               # testes e demonstração (rodam sem interface)
├─ tests/               # (reservado para testes futuros)
└─ docs/                # toda a documentação de design (GDD, bíblia, TDD, etc.)
```

## Sobre a IP

Nomes e lore são **originais** (o abrigo é "o Poço", a autoridade "o Núcleo", etc.), inspirados *tematicamente* na trilogia *Silo* de Hugh Howey, sem usar seus nomes ou conteúdo. Ver `docs/03_Biblia_Mundo_Narrativa.md`.
