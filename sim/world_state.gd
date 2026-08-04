class_name WorldState
extends RefCounted

## O estado inteiro da simulação, serializável e SEM qualquer referência
## a nós visuais / UI. A camada de apresentação (Fase 2) apenas LÊ este
## estado. Isso mantém a simulação testável "headless" e os saves limpos.

var turn: int = 1
var attention: int = Balance.ATTENTION_PER_TURN
var res: Dictionary = {}                 # {"Ar": float, "Energia": float, "Comida": float}
var suspicion: float = Balance.SUS_START
var rebellion: float = 0.0
var martyr_floor: float = 0.0            # piso permanente de rebelião (cicatrizes de exílio)
var cons_rate: float = Balance.CONS_START
var calm_uses: int = 0
var residents: Array[Resident] = []
var exiles: int = 0
var exiled_names: Array[String] = []
var rng: SeededRng
var log_lines: Array[String] = []
var over: bool = false
var won: bool = false
var end_reason: String = ""

# --- Derivados (produção/consumo) ---

func active_workers(sys: String) -> int:
	var n := 0
	for r in residents:
		if r.job == sys and not r.isolated:
			n += 1
	return n

## Penalidade da suspeita na produção: 1.0 (sem penalidade) até 0.15.
func sus_penalty() -> float:
	return maxf(Balance.SUS_PENALTY_FLOOR, 1.0 - suspicion / Balance.SUS_PENALTY_DIV)

func production(sys: String) -> float:
	return active_workers(sys) * float(Balance.YIELD_PER_WORKER[sys]) * sus_penalty()

func consumption() -> float:
	return residents.size() * cons_rate

func net_delta(sys: String) -> float:
	return production(sys) - consumption()

# --- Consultas sobre a população ---

func count_state(state: String, exclude_isolated: bool = true) -> int:
	var n := 0
	for r in residents:
		if r.state == state and (not exclude_isolated or not r.isolated):
			n += 1
	return n

## Retorna moradores num dado estado e condição de isolamento.
func residents_where(state: String, isolated: bool) -> Array:
	var out: Array = []
	for r in residents:
		if r.state == state and r.isolated == isolated:
			out.append(r)
	return out

func find_by_id(id: int) -> Resident:
	for r in residents:
		if r.id == id:
			return r
	return null
