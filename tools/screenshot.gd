extends SceneTree

## Ferramenta manual (não faz parte da suíte): instancia main.tscn headless
## com um viewport de tamanho fixo, deixa a UI assentar por alguns frames e
## salva um PNG. Usado durante a Fase 5 para conferir a passada de arte
## sem abrir janela. Uso: godot --headless --script res://tools/screenshot.gd -- <saida.png> [turnos_a_avancar]

func _init() -> void:
	root.size = Vector2i(1400, 900)
	var scene: PackedScene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)

	for i in range(3):
		await process_frame

	var args := OS.get_cmdline_user_args()
	var out_path := args[0] if args.size() > 0 else "res://tools/_screenshot.png"
	var turns := int(args[1]) if args.size() > 1 else 0
	for i in range(turns):
		inst.game.advance_turn()
	if args.size() > 2 and args[2] != "":
		inst._on_select_resident(inst.game.s.residents[0])
	inst._render()

	for i in range(6):
		await process_frame

	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("SAVED:" + out_path)
	quit()
