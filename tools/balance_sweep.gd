extends SceneTree

## Ferramenta de balanceamento em massa (Fase 4, Parte A).
## Joga GAMES_PER_STRATEGY partidas para cada estratégia automática e
## imprime a taxa de vitória. Usada para RE-CALIBRAR sim/balance.gd sempre
## que a escala (POP_SIZE, SYSTEMS, MAX_TURN) mudar, até a forma da
## dificuldade bater o alvo do GDD §15.4:
##   - "ignora_verdade"  -> derrota quase certa (< 15%)
##   - "so_isola"/"so_acalma" (uma ferramenta só) -> vencível mas difícil (35–65%)
##   - "exila_serie"     -> funciona, mas arriscado (a cicatriz encurrala)
##   - "misto"           -> mistura ferramentas com timing = caminho de mestre (o mais alto)
##
## Rodar com:
##   godot --headless --script res://tools/balance_sweep.gd

const GAMES_PER_STRATEGY := 600
const SEED_BASE := 900000

func _init() -> void:
	print("== Sweep de balanceamento — O Poço ==")
	print("Escala: POP_SIZE=%d SYSTEMS=%d BASE_STAFF=%d MAX_TURN=%d SEED_KNOWERS_COUNT=%d" % [
		Balance.POP_SIZE, Balance.SYSTEMS.size(), Balance.BASE_STAFF, Balance.MAX_TURN, Balance.SEED_KNOWERS_COUNT])
	print("")
	_run_strategy("ignora_verdade", _step_ignore)
	_run_strategy("so_isola", _step_isolate_only)
	_run_strategy("so_acalma", _step_calm_only)
	_run_strategy("exila_serie", _step_exile_series)
	_run_strategy("misto", _step_mixed)
	quit(0)

func _run_strategy(name: String, step: Callable) -> void:
	var wins := 0
	var turns_sum := 0
	var loss_physical := 0
	var loss_suspicion := 0
	var loss_rebellion := 0
	for i in GAMES_PER_STRATEGY:
		var g := SimGame.new()
		var s := g.new_game(SEED_BASE + i)
		while not s.over:
			var guard := 0
			while s.attention > 0 and guard < 20:
				guard += 1
				step.call(g, s)
			g.advance_turn()
		if s.won:
			wins += 1
		elif "físico" in s.end_reason:
			loss_physical += 1
		elif "certeza" in s.end_reason:
			loss_suspicion += 1
		elif "rebelião" in s.end_reason:
			loss_rebellion += 1
		turns_sum += s.turn
	var rate := float(wins) / float(GAMES_PER_STRATEGY) * 100.0
	var avg_turns := float(turns_sum) / float(GAMES_PER_STRATEGY)
	print("  %-14s vitória: %5.1f%%  (%d/%d)  turno médio: %.1f  derrotas: físico=%d suspeita=%d rebelião=%d" % [
		name, rate, wins, GAMES_PER_STRATEGY, avg_turns, loss_physical, loss_suspicion, loss_rebellion])

# ------------------------------------------------------------- estratégias

func _lowest_res(s: WorldState) -> String:
	var lo := Balance.SYSTEMS[0]
	for sys in Balance.SYSTEMS:
		if s.res[sys] < s.res[lo]:
			lo = sys
	return lo

func _first_active_knower(s: WorldState) -> Resident:
	for r in s.residents:
		if r.state == "sabe" and not r.isolated:
			return r
	return null

## Reserva de mão-de-obra livre pra substituir quem for isolado sem abrir
## vaga. Sem isso, isolar cedo demais esvazia o posto e mata pelo físico.
func _idle_count(s: WorldState) -> int:
	var n := 0
	for r in s.residents:
		if r.job == "" and not r.isolated:
			n += 1
	return n

## Nunca usa isolar/acalmar/exilar — só tapa buraco de recurso.
func _step_ignore(g: SimGame, s: WorldState) -> void:
	g.patch(_lowest_res(s))

## Reserva só a 1ª ação do turno para a ferramenta (isolar); o resto
## sempre cuida da economia. Representa "uma ferramenta só" jogada com
## juízo — não gasta o turno inteiro na ferramenta às custas dos recursos.
func _step_isolate_only(g: SimGame, s: WorldState) -> void:
	if s.attention == Balance.ATTENTION_PER_TURN:
		var knower := _first_active_knower(s)
		if knower != null:
			g.isolate(knower)
			return
	g.patch(_lowest_res(s))

## Idem, com acalmar como a única ferramenta social.
func _step_calm_only(g: SimGame, s: WorldState) -> void:
	if s.attention == Balance.ATTENTION_PER_TURN and s.suspicion > 30.0:
		g.calm()
		return
	g.patch(_lowest_res(s))

## Exila quem sabe (ferramenta radical, cria cicatriz permanente).
func _step_exile_series(g: SimGame, s: WorldState) -> void:
	var knower := _first_active_knower(s)
	if knower != null:
		g.exile(knower)
	else:
		g.patch(_lowest_res(s))

## Mistura as ferramentas com bom timing: só a 1ª ação do turno lida com
## a ameaça social mais urgente (isolar > acalmar > exilar, nessa ordem
## de prioridade e custo), as demais SEMPRE cuidam da economia. É o
## "caminho de mestre": nunca deixa os recursos morrerem por perseguir
## a verdade, nem ignora a verdade por focar só em recursos.
func _step_mixed(g: SimGame, s: WorldState) -> void:
	if s.attention == Balance.ATTENTION_PER_TURN:
		# Isolar corta a fonte assim que ela aparece — não espera a suspeita
		# incomodar, porque quem sabe ativo continua gerando desconfiados
		# a cada turno (self-advance) e adiar só empilha o problema. Mas só
		# isola se sobrar gente livre pra cobrir o posto (ou se a suspeita já
		# é emergência) — sem isso a vaga fica aberta e mata pelo físico.
		# Acalmar é reservado pra quando não há fonte segura pra cortar mas a
		# suspeita já incomoda — o alívio de retaguarda, não a 1ª linha.
		var knower := _first_active_knower(s)
		if knower != null and (_idle_count(s) > 0 or s.suspicion > 55.0):
			g.isolate(knower)
			return
		elif s.suspicion > 30.0:
			g.calm()
			return
	g.patch(_lowest_res(s))
