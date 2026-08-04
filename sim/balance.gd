class_name Balance
extends RefCounted

## TODOS os números de balanceamento vivem aqui (design data-driven).
## Valores calibrados por ~15 mil partidas automáticas + playtest do
## protótipo. Ver docs/02_GDD (seção 15) para a justificativa de cada um.
## Ajuste aqui para retunar o jogo — nunca espalhe constantes pelo código.

# --- Turno / partida ---
const ATTENTION_PER_TURN := 3
const MAX_TURN := 14

# --- Sistemas e recursos ---
const SYSTEMS := ["Ar", "Energia", "Comida"]
const YIELD_PER_WORKER := {"Ar": 8.0, "Energia": 8.0, "Comida": 7.5}
const RES_START := {"Ar": 64.0, "Energia": 62.0, "Comida": 60.0}
const RES_MAX := 100.0

# --- População ---
const POP_SIZE := 10
const BASE_STAFF := 3            # trabalhadores "cheios" por sistema
const SEED_KNOWERS := [4, 7]     # índices que já começam sabendo
const NAMES := ["Marta", "Nael", "Bruno", "Cléo", "Ivo", "Rosa", "Dante", "Lena", "Ciro", "Vera"]

# --- Economia ---
const SUS_START := 8.0
const CONS_START := 2.3
const CONS_CREEP := 0.06         # consumo/morador sobe a cada turno (escalada)
const SUS_PENALTY_DIV := 175.0   # penalidade de produção = 1 - suspeita/DIV
const SUS_PENALTY_FLOOR := 0.15  # produção nunca cai abaixo de 15%

# --- Ações ---
const PATCH_AMOUNT := 8.0
const CALM_BASE := 14            # suspeita reduzida por "acalmar"
const CALM_MIN := 5              # piso do efeito (rende menos a cada uso)

# --- Difusão da verdade ---
const SPREAD_CHANCE := 0.40      # chance de um "sabe" contaminar por rolagem
const SPREAD_ROLLS := 2
const SPREAD_TO_KNOW := 0.6      # se há desconfiado: 60% vira "sabe", senão cria desconfiado
const SPONT_BASE := 0.05         # pressão de base: alguém desconfia sozinho
const SPONT_GROW := 0.015        # ...e cresce a cada turno ("a mentira envelhece")
const SELF_BASE := 0.05          # desconfiado vira "sabe" sozinho
const SELF_GROW := 0.008
const ISO_LEAK_SUS := 1.5        # cada isolado que sabe vaza boatos (suspeita/turno)
const ISO_LEAK_CONVERT := 0.15   # ...e pode gerar um desconfiado

# --- Suspeita ---
const SUS_PER_KNOWER := 2.5
const SUS_PER_DOUBTER := 1.0
const LOW_RES_THRESHOLD := 40.0
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
