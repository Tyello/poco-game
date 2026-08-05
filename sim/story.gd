class_name Story
extends RefCounted

## Gerador de micro-histórias (Fase 3): recebe o WorldState + o contexto de
## um evento e devolve texto para o feed narrativo. Puramente cosmético —
## NUNCA altera recursos/suspeita/rebelião/estado de moradores. Quem chama
## isto (sim/sim_game.gd) empurra o retorno em s.story_log_lines.

## Alguém passou a "sabe" (por difusão ou por juntar as peças sozinha).
static func on_knows(s: WorldState, r: Resident) -> String:
	var bonded := s.bonded_with(r.id)
	if not bonded.is_empty():
		var other := s.find_by_id(bonded[0])
		if other != null:
			return "%s confidenciou o que descobriu a %s." % [r.given_name, other.given_name]
	if Traits.has(r, "curioso"):
		return "%s sempre soube que algo não batia — agora tem certeza." % r.given_name
	if Traits.has(r, "cetico"):
		return "Cética como sempre, %s não se surpreendeu com o que descobriu." % r.given_name
	if Traits.has(r, "protetor"):
		return "%s guardou a descoberta para não assustar quem ama — mas agora sabe." % r.given_name
	if Traits.has(r, "pragmatico"):
		return "%s não perdeu tempo se abalando: só quis saber o que fazer com a verdade." % r.given_name
	return "%s descobriu a verdade sobre o Poço." % r.given_name

## Alguém foi isolada.
static func on_isolate(s: WorldState, r: Resident) -> String:
	var bonded := s.bonded_with(r.id)
	if not bonded.is_empty():
		var other := s.find_by_id(bonded[0])
		if other != null:
			return "%s pergunta todo dia por %s." % [other.given_name, r.given_name]
	if Traits.has(r, "orgulhoso"):
		return "%s aceitou o isolamento sem uma palavra de protesto — orgulho até o fim." % r.given_name
	if Traits.has(r, "sonhador"):
		return "%s passa os dias isolada olhando para onde imagina que fica a Superfície." % r.given_name
	return "%s foi isolada. O silêncio em torno dela pesa." % r.given_name

## Alguém foi exilada. `bonded_ids` é capturado ANTES da remoção do
## morador de s.residents (o vínculo em si sobrevive em s.bonds).
static func on_exile(s: WorldState, exiled: Resident, bonded_ids: Array[int]) -> Array[String]:
	var lines: Array[String] = []
	for id in bonded_ids:
		var other := s.find_by_id(id)
		if other != null:
			lines.append("Desde a Saída de %s, %s anda calada." % [exiled.given_name, other.given_name])
	if lines.is_empty():
		if Traits.has(exiled, "protetor"):
			lines.append("%s foi à Saída protegendo os outros até o fim — ninguém mais teve que ir no lugar dela." % exiled.given_name)
		elif Traits.has(exiled, "sonhador"):
			lines.append("%s foi à Saída sonhando com a Superfície que nunca chegou a ver." % exiled.given_name)
		else:
			lines.append("%s foi à Saída. Ninguém falou nada, mas todos notaram." % exiled.given_name)
	return lines

## Cena de rotina, sem gatilho de evento — só para dar vida ao feed.
static func on_calm_moment(s: WorldState, r: Resident) -> String:
	if Traits.has(r, "tagarela"):
		return "%s espalhou um boato inofensivo pelo refeitório." % r.given_name
	if Traits.has(r, "devoto"):
		return "%s liderou uma oração silenciosa nos Meios." % r.given_name
	if Traits.has(r, "resmungao"):
		return "%s resmungou sobre a comida, como sempre." % r.given_name
	return "%s cruzou o corredor sem dizer nada." % r.given_name

## Mini-bio de ficha (Fase 4, Parte B): 1-2 frases combinando posto/estrato,
## traço principal e vínculo (se houver). Determinístico, sem rng, e
## puramente cosmético — nunca lido pela lógica de jogo.
static func bio(s: WorldState, r: Resident) -> String:
	var lines: Array[String] = []
	if r.job != "":
		lines.append("%s trabalha no posto de %s, no estrato %s." % [r.given_name, r.job, r.stratum()])
	else:
		lines.append("%s não tem posto fixo — cobre quem falta, onde for preciso." % r.given_name)
	lines.append(_bio_trait_line(r))
	var bonded := s.bonded_with(r.id)
	if not bonded.is_empty():
		var other := s.find_by_id(bonded[0])
		if other != null:
			var kind := ""
			for b in s.bonds:
				if (b["a"] == r.id and b["b"] == other.id) or (b["b"] == r.id and b["a"] == other.id):
					kind = b["kind"]
					break
			var kind_word := "família" if kind == "familia" else "amizade"
			lines.append("Tem um laço de %s com %s." % [kind_word, other.given_name])
	return " ".join(lines)

static func _bio_trait_line(r: Resident) -> String:
	if r.traits.is_empty():
		return "%s ainda é um mistério para os vizinhos." % r.given_name
	match r.traits[0]:
		"cetico":
			return "Não acredita em nada que não possa conferir com as próprias mãos."
		"devoto":
			return "Encontra sentido nos rituais que sobraram do mundo de antes."
		"leal":
			return "Quem tem sua confiança, tem para sempre."
		"resmungao":
			return "Reclama de tudo — e ainda assim nunca falta ao posto."
		"curioso":
			return "Faz perguntas demais para quem vive num lugar de respostas escassas."
		"medroso":
			return "Evita os corredores vazios sempre que pode."
		"tagarela":
			return "Sabe o nome, o posto e o segredo de quase todo mundo."
		"reservado":
			return "Fala pouco, mas repara em tudo."
		"protetor":
			return "Se coloca entre o perigo e quem ama, sem pensar duas vezes."
		"sonhador":
			return "Ainda imagina a Superfície como era antes — mesmo sem nunca a ter visto."
		"pragmatico":
			return "Prefere resultado a discurso; o resto é perda de tempo."
		"orgulhoso":
			return "Não pede ajuda, nem quando devia."
		_:
			return "%s tem seu jeito próprio de levar a vida no Poço." % r.given_name
