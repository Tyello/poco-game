class_name SaveData
extends RefCounted

## Serialização do WorldState (ver docs/04_TDD §6). Só dados — nenhum nó
## visual. `save_version` viaja com o save para permitir migração futura.

const CURRENT_VERSION := 1
const DEFAULT_PATH := "user://save_1.json"

static func to_dict(s: WorldState) -> Dictionary:
	var residents_data := []
	for r in s.residents:
		residents_data.append({
			"id": r.id,
			"name": r.given_name,
			"job": r.job,
			"state": r.state,
			"isolated": r.isolated,
			"traits": r.traits,
		})
	return {
		"save_version": CURRENT_VERSION,
		"turn": s.turn,
		"attention": s.attention,
		"res": s.res,
		"suspicion": s.suspicion,
		"rebellion": s.rebellion,
		"martyr_floor": s.martyr_floor,
		"cons_rate": s.cons_rate,
		"calm_uses": s.calm_uses,
		"exiles": s.exiles,
		"exiled_names": s.exiled_names,
		"residents": residents_data,
		"bonds": s.bonds,
		"log_lines": s.log_lines,
		"story_log_lines": s.story_log_lines,
		"over": s.over,
		"won": s.won,
		"end_reason": s.end_reason,
		# Guardado como String: JSON não preserva inteiros de 64 bits com
		# precisão (vira double na volta) e o estado do RNG precisa ser
		# exato para o determinismo sobreviver ao save/load.
		"rng_state": str(s.rng.get_state()),
	}

static func from_dict(raw: Dictionary) -> WorldState:
	var data := _migrate(raw)
	var s := WorldState.new()
	s.turn = int(data.get("turn", 1))
	s.attention = int(data.get("attention", Balance.ATTENTION_PER_TURN))
	s.res = (data.get("res", {}) as Dictionary).duplicate()
	s.suspicion = float(data.get("suspicion", Balance.SUS_START))
	s.rebellion = float(data.get("rebellion", 0.0))
	s.martyr_floor = float(data.get("martyr_floor", 0.0))
	s.cons_rate = float(data.get("cons_rate", Balance.CONS_START))
	s.calm_uses = int(data.get("calm_uses", 0))
	s.exiles = int(data.get("exiles", 0))
	var exiled_names: Array[String] = []
	for n in data.get("exiled_names", []):
		exiled_names.append(String(n))
	s.exiled_names = exiled_names

	var residents: Array[Resident] = []
	for rd in data.get("residents", []):
		var r := Resident.new(int(rd["id"]), String(rd["name"]), String(rd["job"]))
		r.state = String(rd["state"])
		r.isolated = bool(rd["isolated"])
		var traits: Array[String] = []
		for t in rd.get("traits", []):
			traits.append(String(t))
		r.traits = traits
		residents.append(r)
	s.residents = residents

	var bonds: Array[Dictionary] = []
	for b in data.get("bonds", []):
		bonds.append({"a": int(b["a"]), "b": int(b["b"]), "kind": String(b["kind"])})
	s.bonds = bonds

	var log_lines: Array[String] = []
	for l in data.get("log_lines", []):
		log_lines.append(String(l))
	s.log_lines = log_lines
	var story_log_lines: Array[String] = []
	for l in data.get("story_log_lines", []):
		story_log_lines.append(String(l))
	s.story_log_lines = story_log_lines

	s.over = bool(data.get("over", false))
	s.won = bool(data.get("won", false))
	s.end_reason = String(data.get("end_reason", ""))

	s.rng = SeededRng.new(0)
	s.rng.set_state(int(String(data.get("rng_state", "0"))))
	return s

## Ponto único de migração. Saves sem save_version são tratados como v1.
static func _migrate(raw: Dictionary) -> Dictionary:
	var data := raw.duplicate(true)
	if not data.has("save_version"):
		data["save_version"] = 1
	# Migrações de versões futuras entram aqui, uma de cada vez.
	return data

static func save_to_file(s: WorldState, path: String = DEFAULT_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(to_dict(s), "\t"))
	f.close()

## Retorna null se o arquivo não existir ou não puder ser lido como JSON.
static func load_from_file(path: String = DEFAULT_PATH) -> WorldState:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return from_dict(parsed)
