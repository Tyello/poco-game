class_name SimGame
extends RefCounted

## O motor da simulação: cria uma partida, aplica as ações do jogador e
## processa o avanço de turno na ordem canônica (ver docs/04_TDD, seção 5).
## Toda a lógica é pura (sem UI). A camada visual chamará estes métodos.
##
## Uso:
##   var game := SimGame.new()
##   var s := game.new_game(42)
##   game.isolate(algum_morador)
##   game.patch("Energia")
##   game.advance_turn()
##   ... ler s.res, s.suspicion, s.over, etc.

var s: WorldState

# ---------------------------------------------------------------- setup

func new_game(seed_value: int = 0) -> WorldState:
	s = WorldState.new()
	s.rng = SeededRng.new(seed_value)
	s.res = Balance.RES_START.duplicate()
	s.residents = []
	for i in Balance.POP_SIZE:
		var job := ""
		if i < 9:
			job = Balance.SYSTEMS[i % 3]
		s.residents.append(Resident.new(i, Balance.NAMES[i], job))
	for idx in Balance.SEED_KNOWERS:
		s.residents[idx].state = "sabe"
	_assign_traits()
	_generate_bonds()
	s.log_lines.append("Dois moradores já sabem demais. A mentira envelhece a cada turno.")
	return s

## Sorteia 1-2 traços por morador, determinístico via s.rng.
func _assign_traits() -> void:
	for r in s.residents:
		var pool := Traits.POOL.duplicate()
		var t1 = s.rng.pick(pool)
		r.traits.append(t1)
		if s.rng.chance(Balance.TRAIT_SECOND_CHANCE):
			pool.erase(t1)
			var t2 = s.rng.pick(pool)
			r.traits.append(t2)

## Gera Balance.BOND_PAIRS vínculos (família/amizade) entre moradores
## distintos, sem repetir par, determinístico via s.rng.
func _generate_bonds() -> void:
	var ids: Array[int] = []
	for r in s.residents:
		ids.append(r.id)
	var used := {}
	var pairs := 0
	var guard := 0
	while pairs < Balance.BOND_PAIRS and guard < 200:
		guard += 1
		var a = s.rng.pick(ids)
		var b = s.rng.pick(ids)
		if a == b:
			continue
		var key := "%d-%d" % [mini(a, b), maxi(a, b)]
		if used.has(key):
			continue
		used[key] = true
		var kind := "familia" if s.rng.chance(0.5) else "amizade"
		s.bonds.append({"a": a, "b": b, "kind": kind})
		pairs += 1

func _log(t: String) -> void:
	s.log_lines.push_front(t)

## Empurra uma linha no feed narrativo (micro-histórias, Parte B). Puramente
## cosmético — nunca chamado a partir de código que altera medidores.
func _story(t: String) -> void:
	s.story_log_lines.push_front(t)

func _spare() -> Resident:
	for r in s.residents:
		if r.job == "" and not r.isolated:
			return r
	return null

func _backfill(sys: String) -> void:
	var sp := _spare()
	if sp != null:
		sp.job = sys
		_log("%s (sobressalente) assumiu o posto de %s." % [sp.given_name, sys])

# ---------------------------------------------------------------- ações
# Cada ação custa 1 de atenção e retorna true se foi executada.

func patch(sys: String) -> bool:
	if s.attention <= 0:
		return false
	s.attention -= 1
	s.res[sys] = clampf(s.res[sys] + Balance.PATCH_AMOUNT, 0.0, Balance.RES_MAX)
	_log("Reparo emergencial em %s: +%d." % [sys, int(Balance.PATCH_AMOUNT)])
	return true

func calm() -> bool:
	if s.attention <= 0:
		return false
	s.attention -= 1
	var e := maxi(Balance.CALM_MIN, Balance.CALM_BASE - s.calm_uses * 3)
	s.calm_uses += 1
	s.suspicion = clampf(s.suspicion - e, 0.0, 100.0)
	_log("Você acalmou os ânimos. Suspeita -%d (rende menos a cada vez)." % e)
	return true

func isolate(r: Resident) -> bool:
	if r == null or s.attention <= 0 or r.isolated:
		return false
	s.attention -= 1
	var job := r.job
	r.isolated = true
	s.suspicion = clampf(s.suspicion + Balance.ISOLATE_SUS, 0.0, 100.0)
	_log("%s isolada, fora do posto de %s. Não contamina, mas segue consumindo." % [r.given_name, job])
	_story(Story.on_isolate(s, r))
	if job != "":
		_backfill(job)
	return true

func exile(r: Resident) -> bool:
	if r == null or s.attention <= 0:
		return false
	s.attention -= 1
	var job := r.job
	var bonded_ids := s.bonded_with(r.id)
	s.residents.erase(r)
	s.exiles += 1
	s.exiled_names.append(r.given_name)
	s.rebellion = clampf(s.rebellion + Balance.EXILE_REB, 0.0, 100.0)
	s.suspicion = clampf(s.suspicion + Balance.EXILE_SUS, 0.0, 100.0)
	s.martyr_floor = minf(Balance.MARTYR_FLOOR_CAP, s.martyr_floor + Balance.EXILE_MARTYR_FLOOR)
	_log("[Saída] %s condenada à Saída. Piso permanente de revolta agora %d." % [r.given_name, int(s.martyr_floor)])
	for line in Story.on_exile(s, r, bonded_ids):
		_story(line)
	if s.rng.chance(Balance.EXILE_CONVERT_CHANCE):
		var oks := s.residents_where("ok", false)
		# Mesma probabilidade/magnitude de sempre: só muda QUEM é alvo,
		# priorizando um vínculo do exilado quando existir (Parte C).
		var bonded_oks: Array = []
		for o in oks:
			if o.id in bonded_ids:
				bonded_oks.append(o)
		var t = s.rng.pick(bonded_oks) if not bonded_oks.is_empty() else s.rng.pick(oks)
		if t != null:
			t.state = "desconfiada"
			if t.id in bonded_ids:
				_log("A Saída do vínculo de %s fez %s começar a desconfiar." % [r.given_name, t.given_name])
				_story("A Saída de %s partiu o coração de %s." % [r.given_name, t.given_name])
			else:
				_log("A Saída de %s não passou despercebida: %s começou a desconfiar." % [r.given_name, t.given_name])
	if job != "":
		_backfill(job)
	return true

func reintegrate(r: Resident) -> bool:
	if r == null or not r.isolated:
		return false
	var full := s.active_workers(r.job) >= Balance.BASE_STAFF
	r.isolated = false
	if full:
		r.job = ""
		_log("%s voltou como sobressalente (o posto já fora coberto)." % r.given_name)
	else:
		_log("%s voltou ao posto de %s." % [r.given_name, r.job])
	return true

# ---------------------------------------------------------------- turno
# Ordem canônica: recursos -> difusão -> pressão de base -> vazamento
# dos isolados -> suspeita -> rebelião -> escalada -> checagem de fim.

func advance_turn() -> void:
	if s.over:
		return

	# 1. Recursos (produção - consumo)
	for sys in Balance.SYSTEMS:
		s.res[sys] = clampf(s.res[sys] + s.net_delta(sys), 0.0, Balance.RES_MAX)

	# 2. Difusão ativa: quem SABE empurra alguém um estágio
	var spreaders := s.residents_where("sabe", false)
	if not spreaders.is_empty():
		for _roll in Balance.SPREAD_ROLLS:
			if s.rng.chance(Balance.SPREAD_CHANCE):
				var doubters := s.residents_where("desconfiada", false)
				var oks := s.residents_where("ok", false)
				if not doubters.is_empty() and s.rng.chance(Balance.SPREAD_TO_KNOW):
					var t = s.rng.pick(doubters)
					t.state = "sabe"
					_log("%s passou de desconfiada a SABER." % t.given_name)
					_story(Story.on_knows(s, t))
				elif not oks.is_empty():
					var t2 = s.rng.pick(oks)
					t2.state = "desconfiada"
					_log("%s começou a desconfiar." % t2.given_name)

	# 2b. Pressão de base — a verdade nunca some e ESCALA com o tempo
	var spont := Balance.SPONT_BASE + (s.turn - 1) * Balance.SPONT_GROW
	var self_adv := Balance.SELF_BASE + (s.turn - 1) * Balance.SELF_GROW
	var oks2 := s.residents_where("ok", false)
	if not oks2.is_empty() and s.rng.chance(spont):
		var t3 = s.rng.pick(oks2)
		t3.state = "desconfiada"
		_log("%s notou uma inconsistência e começou a desconfiar." % t3.given_name)
	for r in s.residents_where("desconfiada", false):
		if s.rng.chance(self_adv):
			r.state = "sabe"
			_log("%s juntou as peças sozinha — agora sabe." % r.given_name)
			_story(Story.on_knows(s, r))

	# 2c. Isolados vazam boatos ("os que somem")
	var iso := s.residents_where("sabe", true)
	if not iso.is_empty():
		s.suspicion = clampf(s.suspicion + iso.size() * Balance.ISO_LEAK_SUS, 0.0, 100.0)
		for _i in iso:
			if s.rng.chance(Balance.ISO_LEAK_CONVERT):
				var oks3 := s.residents_where("ok", false)
				if not oks3.is_empty():
					var t4 = s.rng.pick(oks3)
					t4.state = "desconfiada"

	# 2d. Momento tranquilo (cosmético — não lê nem altera nenhum medidor)
	if s.rng.chance(Balance.STORY_CALM_MOMENT_CHANCE):
		var calm_pool := s.residents_where("ok", false)
		if not calm_pool.is_empty():
			var p = s.rng.pick(calm_pool)
			_story(Story.on_calm_moment(s, p))

	# 3. Suspeita
	var kc := s.count_state("sabe")
	var dc := s.count_state("desconfiada")
	var g := kc * Balance.SUS_PER_KNOWER + dc * Balance.SUS_PER_DOUBTER
	if s.res["Ar"] < Balance.LOW_RES_THRESHOLD or s.res["Energia"] < Balance.LOW_RES_THRESHOLD or s.res["Comida"] < Balance.LOW_RES_THRESHOLD:
		g += Balance.LOW_RES_SUS
	s.suspicion = clampf(s.suspicion + g, 0.0, 100.0)
	if s.suspicion < Balance.SUS_DECAY_BELOW:
		s.suspicion = clampf(s.suspicion - Balance.SUS_DECAY, 0.0, 100.0)

	# 4. Rebelião (com piso permanente de mártires)
	if s.suspicion > Balance.REB_SUS_THRESHOLD:
		s.rebellion = clampf(s.rebellion + (s.suspicion - Balance.REB_SUS_THRESHOLD) * Balance.REB_GROW_MULT, 0.0, 100.0)
	elif s.suspicion < Balance.REB_DECAY_BELOW:
		s.rebellion = clampf(s.rebellion - Balance.REB_DECAY, 0.0, 100.0)
	if s.rebellion < s.martyr_floor:
		s.rebellion = s.martyr_floor

	# 5. Escalada
	s.cons_rate += Balance.CONS_CREEP

	# 6. Condições de fim
	var reason := ""
	if s.res["Ar"] <= 0.0:
		reason = "o ar acabou"
	elif s.res["Energia"] <= 0.0:
		reason = "o gerador morreu"
	elif s.res["Comida"] <= 0.0:
		reason = "a fome venceu"
	if reason != "":
		_finish(false, "Colapso físico — %s." % reason)
		return
	if s.suspicion >= 100.0:
		_finish(false, "A suspeita virou certeza. A multidão tomou o refeitório.")
		return
	if s.rebellion >= 100.0:
		_finish(false, "Colapso social — a rebelião tomou o Poço.")
		return

	# 7. Próximo turno
	s.turn += 1
	if s.turn > Balance.MAX_TURN:
		_finish(true, "Você atravessou %d turnos. O Poço resistiu — e você sabe o preço exato." % Balance.MAX_TURN)
		return
	s.attention = Balance.ATTENTION_PER_TURN
	_log("— Turno %d — (a pressão da verdade aumentou)" % s.turn)

func _finish(win: bool, msg: String) -> void:
	s.over = true
	s.won = win
	s.end_reason = msg
	_log(msg)
