class_name Resident
extends RefCounted

## Um morador do Poço. Trabalha num posto (sistema) e tem um estágio
## de conhecimento da verdade: tranquilo -> desconfiado -> sabe.

var id: int
var given_name: String
var surname: String = ""        # ver Balance.SURNAMES (Fase 4, Parte B)
var job: String = ""            # "", "Ar", "Energia", "Comida"
var state: String = "ok"        # "ok" (tranquilo), "desconfiada", "sabe"
var isolated: bool = false
var traits: Array[String] = []  # 1-2 traços, ver sim/traits.gd (Fase 3)

func _init(_id: int = 0, _name: String = "", _job: String = "") -> void:
	id = _id
	given_name = _name
	job = _job

func knows() -> bool:
	return state == "sabe"

func doubts() -> bool:
	return state == "desconfiada"

func full_name() -> String:
	return "%s %s" % [given_name, surname]

## Estrato temático do posto ("" se sem posto). Ver Balance.SYSTEM_STRATUM.
func stratum() -> String:
	if job == "":
		return ""
	return Balance.SYSTEM_STRATUM.get(job, "")

## Humor atual, derivado do estágio de verdade e isolamento. Puro (sem
## rng, sem estado novo) — só leitura do que já existe no morador.
func mood() -> String:
	if isolated:
		return "resignada"
	if state == "sabe":
		return "decidida"
	if state == "desconfiada":
		return "inquieta"
	return "tranquila"
