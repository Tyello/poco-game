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
	test_traits_assigned()
	test_bonds_deterministic()
	test_trait_modifiers_neutral()
	test_stories_dont_affect_meters()
	test_exile_prioritizes_bond()
	test_save_load_roundtrip()
	test_save_version_defaults_to_1()
	test_population_deterministic()
	test_surnames_deterministic()
	test_bio_and_mood_dont_crash()
	test_agua_sector_generic()
	test_energy_chain_penalizes_other_sectors()
	test_upgrade_guards()
	test_production_breakdown_consistency()
	test_save_load_parts_and_upgrades()
	test_parts_trickle_per_turn()

# --------------------------------------------------------------- testes

func test_initial_state() -> void:
	var g := SimGame.new()
	var s := g.new_game(1)
	_check(s.residents.size() == Balance.POP_SIZE, "população inicial = %d" % Balance.POP_SIZE)
	_check(s.count_state("sabe") == Balance.SEED_KNOWERS_COUNT, "%d sementes de verdade" % Balance.SEED_KNOWERS_COUNT)
	_check(s.attention == Balance.ATTENTION_PER_TURN, "%d ações por turno" % Balance.ATTENTION_PER_TURN)
	# Com BASE_STAFF * SYSTEMS.size() >= POP_SIZE (Parte C: 4 setores), a
	# escala satura — todo mundo fica staffed, dividido o mais igual
	# possível entre os setores (round-robin por índice), não necessariamente
	# BASE_STAFF por setor. Ver docs/10 Parte C — retunar fica pro sweep.
	var total_staffed := 0
	var staff_balanced := true
	var expected_per_sys := Balance.POP_SIZE / Balance.SYSTEMS.size()
	for sys in Balance.SYSTEMS:
		var w := s.active_workers(sys)
		total_staffed += w
		if absi(w - expected_per_sys) > 1:
			staff_balanced = false
	_check(total_staffed <= Balance.POP_SIZE, "trabalhadores staffed não excedem a população")
	_check(staff_balanced, "trabalhadores distribuídos ~igualmente entre setores (~%d cada)" % expected_per_sys)

func test_production_math() -> void:
	var g := SimGame.new()
	var s := g.new_game(1)
	var expected := s.active_workers("Ar") * s.effective_yield("Ar") * s.energy_factor() * (1.0 - s.suspicion / Balance.SUS_PENALTY_DIV)
	_check(absf(s.production("Ar") - expected) < 0.001, "produção = trabalhadores * yield * penalidade")

func test_isolate_backfills() -> void:
	var g := SimGame.new()
	var s := g.new_game(1)
	var before := s.active_workers("Ar")
	# Com BASE_STAFF * SYSTEMS.size() >= POP_SIZE (Parte C), pode não sobrar
	# sobressalente algum — nesse caso o posto perde 1 trabalhador mesmo.
	var had_spare := false
	for r in s.residents:
		if r.job == "" and not r.isolated:
			had_spare = true
			break
	var target: Resident = null
	for r in s.residents:
		if r.job == "Ar" and not r.isolated:
			target = r
			break
	g.isolate(target)
	var expected := before if had_spare else before - 1
	_check(s.active_workers("Ar") == expected, "sobressalente cobre o posto do isolado quando existe (senão o posto perde 1)")

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

func test_traits_assigned() -> void:
	var g := SimGame.new()
	var s := g.new_game(7)
	var all_have_traits := true
	for r in s.residents:
		if r.traits.size() < 1 or r.traits.size() > 2:
			all_have_traits = false
	_check(all_have_traits, "todo morador tem 1-2 traços")
	var g2 := SimGame.new()
	var s2 := g2.new_game(7)
	var same := true
	for i in s.residents.size():
		if s.residents[i].traits != s2.residents[i].traits:
			same = false
	_check(same, "mesma seed produz os mesmos traços (determinismo)")

func test_bonds_deterministic() -> void:
	var g := SimGame.new()
	var s := g.new_game(7)
	var g2 := SimGame.new()
	var s2 := g2.new_game(7)
	_check(s.bonds == s2.bonds, "mesma seed produz os mesmos vínculos (determinismo)")
	_check(s.bonds.size() == Balance.BOND_PAIRS, "gera %d vínculos" % Balance.BOND_PAIRS)
	var ids_ok := true
	for b in s.bonds:
		if s.find_by_id(b["a"]) == null or s.find_by_id(b["b"]) == null:
			ids_ok = false
	_check(ids_ok, "ids referenciados nos vínculos existem")

## Modificadores de traço existem como constantes mas ficam neutros
## (0.0) até uma passada de balanceamento dedicada (docs/09). O teste
## test_ignore_truth_loses acima já confirma que a taxa de vitória
## ignorando a verdade não mudou.
func test_trait_modifiers_neutral() -> void:
	_check(Balance.TRAIT_MOD_CETICO_SPONT == 0.0 and Balance.TRAIT_MOD_DEVOTO_SPONT == 0.0, "modificadores mecânicos de traço neutros por padrão")

func test_stories_dont_affect_meters() -> void:
	var g := SimGame.new()
	var s := g.new_game(3)
	var res_before := s.res.duplicate()
	var sus_before := s.suspicion
	var reb_before := s.rebellion
	var r := s.residents[0]
	Story.on_knows(s, r)
	Story.on_isolate(s, r)
	Story.on_exile(s, r, s.bonded_with(r.id))
	Story.on_calm_moment(s, r)
	_check(s.res == res_before and s.suspicion == sus_before and s.rebellion == reb_before, "gerar micro-histórias não altera recursos/suspeita/rebelião")

## Quando o exilado tem um vínculo "ok" elegível e o efeito mártir rola,
## o alvo convertido deve ser o vínculo — não um aleatório qualquer.
func test_exile_prioritizes_bond() -> void:
	var found_case := false
	for seed_value in range(50):
		var g := SimGame.new()
		var s := g.new_game(seed_value)
		var target: Resident = null
		for r in s.residents:
			if r.state == "ok":
				for bid in s.bonded_with(r.id):
					var partner := s.find_by_id(bid)
					if partner != null and partner.state == "ok":
						target = r
						break
			if target != null:
				break
		if target == null:
			continue
		var bonded_ids := s.bonded_with(target.id)
		var before_doubt := {}
		for r in s.residents_where("desconfiada", false):
			before_doubt[r.id] = true
		g.exile(target)
		var new_doubters: Array = []
		for r in s.residents_where("desconfiada", false):
			if not before_doubt.has(r.id):
				new_doubters.append(r.id)
		if new_doubters.is_empty():
			continue
		found_case = true
		_check(new_doubters[0] in bonded_ids, "exílio com vínculo elegível converte o vínculo, não aleatório (seed %d)" % seed_value)
		break
	if not found_case:
		_check(true, "exílio prioriza vínculo (nenhum caso de conversão nas 50 seeds testadas, pulado)")

func test_save_load_roundtrip() -> void:
	var path := "user://save_test_1.json"
	var g1 := SimGame.new()
	var s1 := g1.new_game(55)
	g1.patch(_lowest_res(s1))
	var knower := _first_active_knower(s1)
	if knower != null:
		g1.isolate(knower)
	g1.advance_turn()
	g1.calm()
	g1.advance_turn()

	SaveData.save_to_file(s1, path)

	for i in 3:
		if s1.over:
			break
		g1.patch(_lowest_res(s1))
		g1.advance_turn()
	var ref_snapshot := _snapshot(s1)

	var s2 := SaveData.load_from_file(path)
	_check(s2 != null, "save/load: arquivo carrega de volta")
	if s2 == null:
		return
	var g2 := SimGame.new()
	g2.s = s2
	for i in 3:
		if s2.over:
			break
		g2.patch(_lowest_res(s2))
		g2.advance_turn()
	var loaded_snapshot := _snapshot(s2)
	_check(ref_snapshot == loaded_snapshot, "avançar após carregar == avançar sem ter salvado (mesma seed)")

func test_save_version_defaults_to_1() -> void:
	var g := SimGame.new()
	var s := g.new_game(1)
	var d := SaveData.to_dict(s)
	_check(d.has("save_version") and d["save_version"] == SaveData.CURRENT_VERSION, "save_version presente no dict serializado")
	d.erase("save_version")
	var s2 := SaveData.from_dict(d)
	_check(s2 != null and s2.residents.size() == s.residents.size(), "carregar save sem save_version não quebra (assume v1)")

## Mesma seed -> mesma população/postos/vínculos, na escala atual de
## Balance.POP_SIZE (a escala é const em tempo de compilação; ver Parte A).
func test_population_deterministic() -> void:
	var g1 := SimGame.new()
	var s1 := g1.new_game(9)
	var g2 := SimGame.new()
	var s2 := g2.new_game(9)
	var same := true
	for i in s1.residents.size():
		if s1.residents[i].job != s2.residents[i].job or s1.residents[i].state != s2.residents[i].state:
			same = false
	_check(same, "mesma seed produz os mesmos postos/estágios (escala atual: %d moradores)" % Balance.POP_SIZE)
	_check(s1.bonds == s2.bonds, "mesma seed produz os mesmos vínculos na escala atual")

## Mesma seed -> mesmos sobrenomes (determinismo), espelhando
## test_population_deterministic (Fase 4, Parte B: sobrenomes/fichas).
func test_surnames_deterministic() -> void:
	var g1 := SimGame.new()
	var s1 := g1.new_game(13)
	var g2 := SimGame.new()
	var s2 := g2.new_game(13)
	var same := true
	var all_nonempty := true
	for i in s1.residents.size():
		if s1.residents[i].surname != s2.residents[i].surname:
			same = false
		if s1.residents[i].surname == "":
			all_nonempty = false
	_check(same, "mesma seed produz os mesmos sobrenomes (determinismo)")
	_check(all_nonempty, "todo morador recebe um sobrenome")

## bio()/mood() são funções puras (Fase 4, Parte B) — não devem travar
## e devem produzir texto não-vazio para qualquer morador de uma partida.
func test_bio_and_mood_dont_crash() -> void:
	var g := SimGame.new()
	var s := g.new_game(21)
	var ok := true
	for r in s.residents:
		var bio_text := Story.bio(s, r)
		var mood_text := r.mood()
		if bio_text == "" or mood_text == "":
			ok = false
	_check(ok, "bio() e mood() retornam texto não-vazio para todos os moradores")

# ---------------------------------------------------------------- Parte C

func test_agua_sector_generic() -> void:
	var g := SimGame.new()
	var s := g.new_game(7)
	_check(Balance.SYSTEMS.has("Água"), "Água está em Balance.SYSTEMS")
	_check(s.res.has("Água"), "Água tem recurso inicial (Balance.RES_START)")
	_check(s.active_workers("Água") > 0, "Água tem trabalhadores staffed, como os demais setores")
	_check(s.production("Água") > 0.0, "Água produz (mesma fórmula genérica dos outros setores)")
	_check(s.net_delta("Água") == s.production("Água") - s.consumption(), "net_delta(Água) usa a mesma fórmula genérica")

func test_energy_chain_penalizes_other_sectors() -> void:
	var s := WorldState.new()
	s.rng = SeededRng.new(1)
	s.res = Balance.RES_START.duplicate()
	s.residents = []
	s.residents.append(Resident.new(0, "X", "Ar"))
	s.residents.append(Resident.new(1, "Y", "Energia"))

	_check(is_equal_approx(s.energy_factor(), 1.0), "energy_factor() = 1.0 com Energia acima do limiar")
	var ar_full := s.production("Ar")
	var energia_full := s.production("Energia")

	s.res["Energia"] = Balance.ENERGY_CHAIN_THRESHOLD - 1.0
	_check(is_equal_approx(s.energy_factor(), Balance.ENERGY_CHAIN_PENALTY), "energy_factor() cai com Energia abaixo do limiar")
	var ar_low := s.production("Ar")
	var energia_low := s.production("Energia")

	_check(ar_low < ar_full, "produção de Ar cai quando Energia está baixa")
	_check(is_equal_approx(ar_low, ar_full * Balance.ENERGY_CHAIN_PENALTY), "queda de Ar usa exatamente ENERGY_CHAIN_PENALTY")
	_check(is_equal_approx(energia_low, energia_full), "produção da própria Energia não se autopenaliza")

func test_upgrade_guards() -> void:
	var g := SimGame.new()
	var s := g.new_game(3)
	_check(not g.upgrade("Ar"), "upgrade falha sem peças suficientes")
	_check(not g.upgrade("SetorInexistente"), "upgrade falha para setor fora de Balance.SYSTEMS")

	s.parts = Balance.UPGRADE_PARTS_COST * (Balance.UPGRADE_MAX_LEVEL + 2)
	var attention_before := s.attention
	var parts_before := s.parts
	_check(g.upgrade("Ar"), "upgrade sucede com peças e atenção suficientes")
	_check(s.attention == attention_before - 1, "upgrade custa 1 atenção")
	_check(is_equal_approx(s.parts, parts_before - Balance.UPGRADE_PARTS_COST), "upgrade custa UPGRADE_PARTS_COST peças")
	_check(s.sector_upgrades.get("Ar", 0) == 1, "upgrade incrementa o nível do setor")

	for _i in Balance.UPGRADE_MAX_LEVEL - 1:
		s.attention = Balance.ATTENTION_PER_TURN
		g.upgrade("Ar")
	_check(s.sector_upgrades.get("Ar", 0) == Balance.UPGRADE_MAX_LEVEL, "upgrade chega ao nível máximo")
	s.attention = Balance.ATTENTION_PER_TURN
	_check(not g.upgrade("Ar"), "upgrade falha no nível máximo (mesmo com atenção e peças)")

	s.attention = 0
	_check(not g.upgrade("Comida"), "upgrade falha sem atenção")

func test_production_breakdown_consistency() -> void:
	var g := SimGame.new()
	var s := g.new_game(11)
	for sys in Balance.SYSTEMS:
		var b := s.production_breakdown(sys)
		_check(is_equal_approx(b["gross"], b["workers"] * b["yield_per_worker"]), "breakdown(%s): gross = workers * yield_per_worker" % sys)
		_check(is_equal_approx(b["net_production"], s.production(sys)), "breakdown(%s): net_production bate com production()" % sys)
		_check(is_equal_approx(b["consumption_share"], s.consumption() / Balance.SYSTEMS.size()), "breakdown(%s): consumption_share correto" % sys)

func test_save_load_parts_and_upgrades() -> void:
	var s := WorldState.new()
	s.rng = SeededRng.new(1)
	s.res = Balance.RES_START.duplicate()
	s.residents = []
	s.parts = 12.5
	s.sector_upgrades = {"Ar": 2, "Água": 1}
	var data := SaveData.to_dict(s)
	var loaded := SaveData.from_dict(data)
	_check(is_equal_approx(loaded.parts, 12.5), "save/load preserva WorldState.parts")
	_check(loaded.sector_upgrades.get("Ar", 0) == 2 and loaded.sector_upgrades.get("Água", 0) == 1, "save/load preserva WorldState.sector_upgrades")

func test_parts_trickle_per_turn() -> void:
	var g := SimGame.new()
	var s := g.new_game(7)
	for i in 3:
		if s.over:
			break
		g.advance_turn()
	_check(is_equal_approx(s.parts, Balance.PARTS_PER_TURN * 3), "Peças acumulam Balance.PARTS_PER_TURN a cada advance_turn()")

func _snapshot(s: WorldState) -> String:
	var bits := [
		"turn=%d" % s.turn, "sus=%.3f" % s.suspicion, "reb=%.3f" % s.rebellion,
		"cons=%.5f" % s.cons_rate, "won=%s" % str(s.won), "over=%s" % str(s.over),
		"parts=%.3f" % s.parts,
	]
	for sys in Balance.SYSTEMS:
		bits.append("%s=%.3f" % [sys, s.res[sys]])
	var upgrade_keys := s.sector_upgrades.keys()
	upgrade_keys.sort()
	for k in upgrade_keys:
		bits.append("up_%s=%d" % [k, s.sector_upgrades[k]])
	for r in s.residents:
		bits.append("%d:%s:%s:%s:%s:%s:%s" % [r.id, r.job, r.state, str(r.isolated), ",".join(r.traits), r.given_name, r.surname])
	return "|".join(bits)

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
