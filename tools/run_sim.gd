extends SceneTree

## Demonstração headless: joga uma partida com uma estratégia automática
## e imprime turno a turno. Serve para "ver" a simulação rodando sem UI.
## Rode com:
##   godot --headless --script res://tools/run_sim.gd
## (Opcional) mude a seed na constante abaixo.

const SEED_VALUE := 42

func _init() -> void:
	var g := SimGame.new()
	var s := g.new_game(SEED_VALUE)
	print("== O Poço — simulação automática (seed %d) ==\n" % SEED_VALUE)
	print("Turno | %s | Susp Reb | sabem desconf | ações" % _res_header())
	while not s.over:
		var acts := _play_turn(g, s)
		_print_line(s, acts)
		g.advance_turn()
	print("\nFim: %s" % ("VITÓRIA" if s.won else "DERROTA"))
	print(s.end_reason)
	print("Estado final — %s, Suspeita %d, Rebelião %d, Exílios %d" % [
		_res_summary(s), int(s.suspicion), int(s.rebellion), s.exiles])
	quit(0)

func _res_header() -> String:
	var parts: Array[String] = []
	for sys in Balance.SYSTEMS:
		parts.append(sys.substr(0, 2))
	return " ".join(parts)

func _res_summary(s: WorldState) -> String:
	var parts: Array[String] = []
	for sys in Balance.SYSTEMS:
		parts.append("%s %d" % [sys, int(s.res[sys])])
	return ", ".join(parts)

func _print_line(s: WorldState, acts: String) -> void:
	var parts: Array[String] = []
	for sys in Balance.SYSTEMS:
		parts.append("%2d" % int(s.res[sys]))
	print("  %2d  | %s | %3d  %3d | %2d     %2d      | %s" % [
		s.turn, " ".join(parts),
		int(s.suspicion), int(s.rebellion),
		s.count_state("sabe"), s.count_state("desconfiada"), acts])

func _first_active_knower(s: WorldState) -> Resident:
	for r in s.residents:
		if r.state == "sabe" and not r.isolated:
			return r
	return null

func _lowest_res(s: WorldState) -> String:
	var lo := "Ar"
	for sys in Balance.SYSTEMS:
		if s.res[sys] < s.res[lo]:
			lo = sys
	return lo

## Estratégia: isola quem sabe; acalma se a suspeita subir; senão repara.
func _play_turn(g: SimGame, s: WorldState) -> String:
	var acts: Array[String] = []
	var guard := 0
	while s.attention > 0 and guard < 12:
		guard += 1
		var knower := _first_active_knower(s)
		if knower != null:
			g.isolate(knower)
			acts.append("isola %s" % knower.given_name)
		elif s.suspicion > 30.0:
			g.calm()
			acts.append("acalma")
		else:
			var sys := _lowest_res(s)
			g.patch(sys)
			acts.append("repara %s" % sys)
	return ", ".join(acts)
