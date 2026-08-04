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
	return "%s descobriu a verdade sobre o Poço." % r.given_name

## Alguém foi isolada.
static func on_isolate(s: WorldState, r: Resident) -> String:
	var bonded := s.bonded_with(r.id)
	if not bonded.is_empty():
		var other := s.find_by_id(bonded[0])
		if other != null:
			return "%s pergunta todo dia por %s." % [other.given_name, r.given_name]
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
