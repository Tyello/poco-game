extends SceneTree

## Runner de testes SEM dependências (não precisa do GUT).
## Rode com:
##   godot --headless --script res://tools/run_tests.gd
## Sai com código 1 se algum teste falhar (bom para CI).

var _passed := 0
var _failed := 0

func _init() -> void:
	print("== Testes da simulação — O Poço ==")
	_run_all()
	print("\nResultado: %d passaram, %d falharam." % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _check(cond: bool, name: String) -> void:
	if cond:
		_passed += 1
		print("  [ok]     ", name)
	else:
		_failed += 1
		print("  [FALHOU] ", name)

func _run_all() -> void:
	test_initial_state()
	test_production_math()
	test_isolate_backfills()
	test_exile_raises_floor()
	test_determinism()
	test_ignore_truth_loses()
	test_physical_collapse()
	test_suspicion_collapse()

# --------------------------------------------------------------- testes

func test_initial_state() -> void:
	var g := SimGame.new()
	var s := g.new_game(1)
	_check(s.residents.size() == Balance.POP_SIZE, "população inicial = %d" % Balance.POP_SIZE)
	_check(s.count_state("sabe") == 2, "duas sementes de verdade")
	_check(s.attention == Balance.ATTENTION_PER_TURN, "3 ações por turno")
	_check(s.active_workers("Ar") == 3 and s.active_workers("Energia") == 3 and s.active_workers("Comida") == 3, "3 trabalhadores por sistema")

func test_production_math() -> void:
	var g := SimGame.new()
	var s := g.new_game(1)
	var expected := s.active_workers("Ar") * 8.0 * (1.0 - s.suspicion / Balance.SUS_PENALTY_DIV)
	_check(absf(s.production("Ar") - expected) < 0.001, "produção = trabalhadores * yield * penalidade")

func test_isolate_backfills() -> void:
	var g := SimGame.new()
	var s := g.new_game(1)
	var before := s.active_workers("Ar")
	var target: Resident = null
	for r in s.residents:
		if r.job == "Ar" and not r.isolated:
			target = r
			break
	g.isolate(target)
	_check(s.active_workers("Ar") == before, "sobressalente cobre o posto do isolado (trabalhadores mantidos)")

func test_exile_raises_floor() -> void:
	var g := SimGame.new()
	var s := g.new_game(1)
	var target = s.residents_where("sabe", false)[0]
	var reb_before := s.rebellion
	var pop_before := s.residents.size()
	g.exile(target)
	_check(s.martyr_floor >= Balance.EXILE_MARTYR_FLOOR - 0.001, "exílio cria piso permanente de revolta")
	_check(s.rebellion >= reb_before + Balance.EXILE_REB - 0.001, "exílio aumenta a rebelião")
	_check(s.residents.size() == pop_before - 1, "exílio remove o morador")

func test_determinism() -> void:
	var a := _play_auto(42)
	var b := _play_auto(42)
	_check(a == b, "mesma seed produz o mesmo resultado (determinismo)")

func test_ignore_truth_loses() -> void:
	var wins := 0
	for i in 200:
		var g := SimGame.new()
		var s := g.new_game(1000 + i)
		while not s.over:
			while s.attention > 0:
				g.patch(_lowest_res(s))
			g.advance_turn()
		if s.won:
			wins += 1
	_check(wins < 30, "ignorar a verdade perde quase sempre (vitórias: %d/200)" % wins)

func test_physical_collapse() -> void:
	var g := SimGame.new()
	var s := g.new_game(1)
	s.cons_rate = 100.0   # consumo absurdo força colapso físico
	g.advance_turn()
	_check(s.over and not s.won and ("físico" in s.end_reason), "consumo extremo → colapso físico")

func test_suspicion_collapse() -> void:
	var g := SimGame.new()
	var s := g.new_game(1)
	s.suspicion = 100.0
	g.advance_turn()
	_check(s.over and not s.won, "suspeita em 100 → derrota social")

# --------------------------------------------------------- utilidades

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

## Estratégia automática determinística: isola quem sabe, acalma se a
## suspeita subir, senão tapa o recurso mais baixo. Usada para testar.
func _play_auto(seed_value: int) -> String:
	var g := SimGame.new()
	var s := g.new_game(seed_value)
	while not s.over:
		var guard := 0
		while s.attention > 0 and guard < 12:
			guard += 1
			var knower := _first_active_knower(s)
			if knower != null:
				g.isolate(knower)
			elif s.suspicion > 30.0:
				g.calm()
			else:
				g.patch(_lowest_res(s))
		g.advance_turn()
	return "turn=%d won=%s sus=%d reb=%d ar=%d en=%d co=%d" % [
		s.turn, str(s.won), int(s.suspicion), int(s.rebellion),
		int(s.res["Ar"]), int(s.res["Energia"]), int(s.res["Comida"])]
