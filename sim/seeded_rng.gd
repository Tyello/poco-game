class_name SeededRng
extends RefCounted

## Gerador de aleatoriedade determinístico.
## TODA aleatoriedade da simulação deve passar por aqui, para que
## a mesma seed produza sempre o mesmo resultado (essencial para
## testes reproduzíveis e para o futuro modo roguelite).

var _rng := RandomNumberGenerator.new()

func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value

func randf() -> float:
	return _rng.randf()

## Retorna true com probabilidade p (0.0 a 1.0).
func chance(p: float) -> bool:
	return _rng.randf() < p

## Escolhe um elemento aleatório do array (ou null se vazio).
func pick(arr: Array):
	if arr.is_empty():
		return null
	return arr[_rng.randi_range(0, arr.size() - 1)]
