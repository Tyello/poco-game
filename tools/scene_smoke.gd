extends SceneTree

## Smoke test manual (não faz parte da suíte): instancia main.tscn headless,
## deixa alguns frames rodarem e sai. Usado durante a Fase 5 para pegar
## erros de script na camada visual sem abrir janela.

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var inst := scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	print("SMOKE_OK")
	quit()
