class_name WorldState
extends RefCounted

## O estado inteiro da simulação, serializável e SEM qualquer referência
## a nós visuais / UI. A camada de apresentação (Fase 2) apenas LÊ este
## estado. Isso mantém a simulação testável "headless" e os saves limpos.

var turn: int = 1
var attention: int = Balance.ATTENTION_PER_TURN
var res: Dictionary = {}                 # {"Ar": float, "Energia": float, "Comida": float, "Água": float}
var suspicion: float = Balance.SUS_START
var rebellion: float = 0.0
var martyr_floor: float = 0.0            # piso permanente de rebelião (cicatrizes de exílio)
var cons_rate: float = Balance.CONS_START
var calm_uses: int = 0
var parts: float = 0.0                   # peças (Fase 4, Parte C) — trickle passivo, financia upgrades
var sector_upgrades: Dictionary = {}     # {sys: int} — nível de upgrade por setor, default 0
var residents: Array[Resident] = []
var bonds: Array[Dictionary] = []       # [{"a": id, "b": id, "kind": "familia"|"amizade"}, ...]
var exiles: int = 0
var exiled_names: Array[String] = []
var rng: SeededRng
var log_lines: Array[String] = []       # registro mecânico (turnos, ações, números)
var story_log_lines: Array[String] = [] # feed narrativo (micro-histórias, Parte B)
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

## Cadeia de energia: Energia baixa penaliza a produção de TODOS os outros
## setores (ela mesma não se estrangula). Ver Balance.ENERGY_CHAIN_*.
func energy_factor() -> float:
	if res.get("Energia", 0.0) >= Balance.ENERGY_CHAIN_THRESHOLD:
		return 1.0
	return Balance.ENERGY_CHAIN_PENALTY

## Rendimento/trabalhador efetivo de um setor, já somando os upgrades
## comprados com peças (Balance.UPGRADE_YIELD_BONUS por nível).
func effective_yield(sys: String) -> float:
	return float(Balance.YIELD_PER_WORKER[sys]) + sector_upgrades.get(sys, 0) * Balance.UPGRADE_YIELD_BONUS

func production(sys: String) -> float:
	var mult := sus_penalty()
	if sys != "Energia":
		mult *= energy_factor()
	return active_workers(sys) * effective_yield(sys) * mult

func consumption() -> float:
	return residents.size() * cons_rate

func net_delta(sys: String) -> float:
	return production(sys) - consumption()

## Detalhamento de produção de um setor, para exibição na UI (Parte C).
## net_production reproduz exatamente production(sys); consumption_share é
## só uma divisão igual do consumo (que continua sendo população-wide) para
## efeito de exibição — não altera a fórmula real de consumo.
func production_breakdown(sys: String) -> Dictionary:
	var workers := active_workers(sys)
	var ypw := effective_yield(sys)
	var gross := workers * ypw
	var energy_mult := 1.0 if sys == "Energia" else energy_factor()
	var sus_mult := sus_penalty()
	return {
		"workers": workers,
		"yield_per_worker": ypw,
		"gross": gross,
		"energy_mult": energy_mult,
		"sus_mult": sus_mult,
		"net_production": gross * energy_mult * sus_mult,
		"consumption_share": consumption() / Balance.SYSTEMS.size(),
	}

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

## Ids de todos os moradores com vínculo direto com `id` (qualquer tipo).
func bonded_with(id: int) -> Array[int]:
	var out: Array[int] = []
	for b in bonds:
		if b["a"] == id:
			out.append(b["b"])
		elif b["b"] == id:
			out.append(b["a"])
	return out
