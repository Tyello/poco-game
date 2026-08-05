class_name Balance
extends RefCounted

## TODOS os números de balanceamento vivem aqui (design data-driven).
## Ajuste aqui para retunar o jogo — nunca espalhe constantes pelo código.
##
## ESCALA-ALVO (Fase 4, Parte A): POP_SIZE=24, 3 setores (Ar/Energia/Comida),
## MAX_TURN=16. Recalibrado por tools/balance_sweep.gd (600 partidas/estratégia)
## até bater a forma-alvo do GDD §15.4 (resultado final do sweep):
##   ignora_verdade 1.2% (<15% ok) | so_isola 42.8% | so_acalma 61.7% (ambos
##   35–65% ok) | exila_serie 19.7% (funciona, mas arriscado — derrota
##   dominada por rebelião) | misto 64.0% (o mais alto — caminho de mestre).
## Ver o comentário de cabeçalho de tools/balance_sweep.gd para o método.
## Qualquer mudança de POP_SIZE/SYSTEMS/MAX_TURN exige rodar o sweep de novo.

# --- Turno / partida ---
const ATTENTION_PER_TURN := 3
const MAX_TURN := 16

# --- Sistemas e recursos ---
# RES_MAX/RES_START/LOW_RES_THRESHOLD escalados por BASE_STAFF/3 (~2.33x):
# o teto de recursos precisa crescer junto com produção/consumo, senão o
# excedente do início do jogo é desperdiçado no clamp e não sobra reserva
# pra fase final (onde suspeita + escalada de consumo apertam mais).
const SYSTEMS := ["Ar", "Energia", "Comida"]
const YIELD_PER_WORKER := {"Ar": 8.0, "Energia": 8.0, "Comida": 7.5}
const RES_START := {"Ar": 149.0, "Energia": 145.0, "Comida": 140.0}
const RES_MAX := 235.0

# --- População ---
const POP_SIZE := 24
const BASE_STAFF := 7            # trabalhadores "cheios" por sistema
const SEED_KNOWERS_COUNT := 3    # nº de moradores que já começam sabendo (sorteado via rng)
const NAMES := [
	"Marta", "Nael", "Bruno", "Cléo", "Ivo", "Rosa", "Dante", "Lena", "Ciro", "Vera",
	"Tomé", "Alba", "Renato", "Sônia", "Judite", "Otávio", "Flor", "Bento", "Iris", "Caio",
	"Nina", "Elias", "Marisa", "Gil",
]

# --- Economia ---
const SUS_START := 8.0
const CONS_START := 2.3
const CONS_CREEP := 0.06         # consumo/morador sobe a cada turno (escalada)
const SUS_PENALTY_DIV := 175.0   # penalidade de produção = 1 - suspeita/DIV
const SUS_PENALTY_FLOOR := 0.15  # produção nunca cai abaixo de 15%

# --- Ações ---
# PATCH_AMOUNT escalado com BASE_STAFF (7/3 do valor original 8.0): a
# produção/consumo total cresce com a população, então o reparo precisa
# manter o mesmo poder de resgate RELATIVO, não o mesmo valor absoluto.
const PATCH_AMOUNT := 19.0
const CALM_BASE := 9             # suspeita reduzida por "acalmar"
const CALM_MIN := 5              # piso do efeito (rende menos a cada uso)

# --- Difusão da verdade ---
const SPREAD_CHANCE := 0.40      # chance de um "sabe" contaminar por rolagem
const SPREAD_ROLLS := 2
const SPREAD_TO_KNOW := 0.6      # se há desconfiado: 60% vira "sabe", senão cria desconfiado
const SPONT_BASE := 0.05         # pressão de base: alguém desconfia sozinho
const SPONT_GROW := 0.015        # ...e cresce a cada turno ("a mentira envelhece")
const SELF_BASE := 0.05          # desconfiado vira "sabe" sozinho
const SELF_GROW := 0.008
const SELF_ROLLS := 2            # rolagens fixas/turno (não por cabeça — ver Parte A)
const ISO_LEAK_SUS := 0.4        # cada isolado que sabe vaza boatos (suspeita/turno) — escalado como SUS_PER_KNOWER
const ISO_LEAK_CONVERT := 0.08   # ...e pode gerar um desconfiado

# --- Suspeita ---
# Contribuição por CABEÇA (não por fração da população) — escalada para
# POP_SIZE=24 a partir do valor original calibrado para 10 (2.5 / 1.0),
# senão populações maiores geram suspeita bruta demais só pelo tamanho.
const SUS_PER_KNOWER := 1.2
const SUS_PER_DOUBTER := 0.5
const LOW_RES_THRESHOLD := 93.0
const LOW_RES_SUS := 3.0
const SUS_DECAY_BELOW := 25.0
const SUS_DECAY := 2.0

# --- Rebelião ---
const REB_SUS_THRESHOLD := 55.0
const REB_GROW_MULT := 0.3
const REB_DECAY_BELOW := 35.0
const REB_DECAY := 2.0

# --- Isolar / Exilar ---
const ISOLATE_SUS := 3.0
const EXILE_REB := 14.0
const EXILE_SUS := 8.0
const EXILE_MARTYR_FLOOR := 22.0 # cada Saída eleva um piso PERMANENTE de rebelião
const MARTYR_FLOOR_CAP := 100.0
const EXILE_CONVERT_CHANCE := 0.5

# --- Traços e vínculos (Fase 3) ---
const TRAIT_SECOND_CHANCE := 0.5 # chance de um morador ter um 2º traço (1 é garantido)
const BOND_PAIRS := 4            # nº de vínculos (família/amizade) gerados em new_game()

# Modificadores mecânicos de traço: reservados para uma passada de
# balanceamento dedicada (ver docs/09, "Fora de escopo"). Ficam em 0.0
# (desligados) e NÃO são aplicados em nenhuma fórmula ainda — existem
# apenas para não obrigar a mexer em balance.gd quando forem ligados.
const TRAIT_MOD_CETICO_SPONT := 0.0  # cético: pressão de base de desconfiança
const TRAIT_MOD_DEVOTO_SPONT := 0.0  # devoto: idem, sentido oposto

# --- Micro-histórias (Fase 3) — cosmético, nunca altera medidores ---
const STORY_CALM_MOMENT_CHANCE := 0.35 # chance/turno de uma cena de rotina no feed
