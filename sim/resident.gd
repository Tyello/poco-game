class_name Resident
extends RefCounted

## Um morador do Poço. Trabalha num posto (sistema) e tem um estágio
## de conhecimento da verdade: tranquilo -> desconfiado -> sabe.

var id: int
var given_name: String
var job: String = ""            # "", "Ar", "Energia", "Comida"
var state: String = "ok"        # "ok" (tranquilo), "desconfiada", "sabe"
var isolated: bool = false

func _init(_id: int = 0, _name: String = "", _job: String = "") -> void:
	id = _id
	given_name = _name
	job = _job

func knows() -> bool:
	return state == "sabe"

func doubts() -> bool:
	return state == "desconfiada"
