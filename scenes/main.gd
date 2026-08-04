extends Control

## Camada visual da Fase 2: instancia SimGame, LÊ WorldState e desenha.
## Nada aqui vaza para dentro de sim/ — esta cena só chama métodos
## públicos de SimGame e lê campos de WorldState (ver CLAUDE.md, regra 1).

const OK_COLOR := Color(0.30, 0.75, 0.40)
const DOUBT_COLOR := Color(0.85, 0.65, 0.15)
const KNOW_COLOR := Color(0.80, 0.20, 0.20)
const ISOLATED_COLOR := Color(0.55, 0.55, 0.60)
const RES_GOOD := Color(0.30, 0.75, 0.40)
const RES_WARN := Color(0.85, 0.65, 0.15)
const RES_BAD := Color(0.80, 0.20, 0.20)
const BG_COLOR := Color(0.08, 0.09, 0.11)

var game: SimGame
var s: WorldState

var meters_box: HBoxContainer
var suspicion_label: Label
var rebellion_label: Label
var attention_label: Label
var turn_label: Label
var log_label: RichTextLabel
var residents_box: VBoxContainer
var actions_box: HBoxContainer
var advance_button: Button
var end_panel: PanelContainer
var end_label: RichTextLabel
var root_layout: VBoxContainer

func _ready() -> void:
	_build_ui()
	game = SimGame.new()
	s = game.new_game(randi())
	_render()

# ---------------------------------------------------------------- UI build

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	root_layout = VBoxContainer.new()
	root_layout.anchor_right = 1.0
	root_layout.anchor_bottom = 1.0
	root_layout.add_theme_constant_override("separation", 8)
	add_child(root_layout)

	actions_box = HBoxContainer.new()
	root_layout.add_child(actions_box)
	_add_action_button("Reparar Ar", func(): _do(game.patch("Ar")))
	_add_action_button("Reparar Energia", func(): _do(game.patch("Energia")))
	_add_action_button("Reparar Comida", func(): _do(game.patch("Comida")))
	_add_action_button("Acalmar", func(): _do(game.calm()))
	attention_label = Label.new()
	actions_box.add_child(attention_label)
	turn_label = Label.new()
	actions_box.add_child(turn_label)

	meters_box = HBoxContainer.new()
	root_layout.add_child(meters_box)
	suspicion_label = Label.new()
	root_layout.add_child(suspicion_label)
	rebellion_label = Label.new()
	root_layout.add_child(rebellion_label)

	var mid := HSplitContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_layout.add_child(mid)

	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_label.custom_minimum_size = Vector2(300, 0)
	mid.add_child(log_label)

	var residents_scroll := ScrollContainer.new()
	residents_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(residents_scroll)
	residents_box = VBoxContainer.new()
	residents_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	residents_scroll.add_child(residents_box)

	advance_button = Button.new()
	advance_button.text = "Avançar turno"
	advance_button.pressed.connect(_on_advance_turn)
	root_layout.add_child(advance_button)

	end_panel = PanelContainer.new()
	end_panel.anchor_right = 1.0
	end_panel.anchor_bottom = 1.0
	end_panel.visible = false
	add_child(end_panel)
	end_label = RichTextLabel.new()
	end_label.bbcode_enabled = true
	end_panel.add_child(end_label)

func _add_action_button(label: String, on_press: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.pressed.connect(on_press)
	actions_box.add_child(b)

# ---------------------------------------------------------------- ações

func _do(_result: bool) -> void:
	_render()

func _on_advance_turn() -> void:
	game.advance_turn()
	_render()

func _on_isolate(r: Resident) -> void:
	game.isolate(r)
	_render()

func _on_exile(r: Resident) -> void:
	game.exile(r)
	_render()

func _on_reintegrate(r: Resident) -> void:
	game.reintegrate(r)
	_render()

# ---------------------------------------------------------------- render

func _render() -> void:
	turn_label.text = "Turno %d" % s.turn
	attention_label.text = "Atenção: %d" % s.attention
	suspicion_label.text = "Suspeita: %d" % int(s.suspicion)
	rebellion_label.text = "Rebelião: %d (piso %d)" % [int(s.rebellion), int(s.martyr_floor)]

	for c in meters_box.get_children():
		c.queue_free()
	for sys in Balance.SYSTEMS:
		meters_box.add_child(_build_meter(sys, s.res[sys]))

	log_label.clear()
	for line in s.log_lines:
		log_label.append_text(line + "\n")

	for c in residents_box.get_children():
		c.queue_free()
	for r in s.residents:
		residents_box.add_child(_build_resident_row(r))

	end_panel.visible = s.over
	if s.over:
		root_layout.visible = false
		end_label.clear()
		end_label.append_text("[b]%s[/b]\n\n" % ("Vitória" if s.won else "Derrota"))
		end_label.append_text(s.end_reason + "\n\n")
		end_label.append_text("Sabiam: %d\n" % s.count_state("sabe"))
		end_label.append_text("Desconfiavam: %d\n" % s.count_state("desconfiada"))
		end_label.append_text("Isolados: %d\n" % s.residents_where("sabe", true).size())
		end_label.append_text("Exilados: %d (%s)\n" % [s.exiles, ", ".join(s.exiled_names)])
	else:
		root_layout.visible = true

func _build_meter(sys: String, value: float) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(90, 0)
	var name_label := Label.new()
	name_label.text = sys
	box.add_child(name_label)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = Balance.RES_MAX
	bar.value = value
	bar.show_percentage = false
	bar.modulate = _res_color(value)
	box.add_child(bar)
	var value_label := Label.new()
	value_label.text = "%d" % int(value)
	box.add_child(value_label)
	return box

func _res_color(value: float) -> Color:
	if value < 30.0:
		return RES_BAD
	if value < 60.0:
		return RES_WARN
	return RES_GOOD

func _state_color(r: Resident) -> Color:
	if r.isolated:
		return ISOLATED_COLOR
	if r.state == "sabe":
		return KNOW_COLOR
	if r.state == "desconfiada":
		return DOUBT_COLOR
	return OK_COLOR

func _build_resident_row(r: Resident) -> Control:
	var row := HBoxContainer.new()

	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(12, 12)
	dot.color = _state_color(r)
	row.add_child(dot)

	var label := Label.new()
	var job_text := r.job if r.job != "" else "sobressalente"
	var state_text := "sabe" if r.state == "sabe" else ("desconfia" if r.state == "desconfiada" else "tranquila")
	if r.isolated:
		state_text += " (isolada)"
	label.text = "%s — %s — %s" % [r.given_name, job_text, state_text]
	label.custom_minimum_size = Vector2(260, 0)
	row.add_child(label)

	if s.attention > 0:
		if r.isolated:
			var reintegrate_btn := Button.new()
			reintegrate_btn.text = "Reintegrar"
			reintegrate_btn.pressed.connect(_on_reintegrate.bind(r))
			row.add_child(reintegrate_btn)
		else:
			var isolate_btn := Button.new()
			isolate_btn.text = "Isolar"
			isolate_btn.pressed.connect(_on_isolate.bind(r))
			row.add_child(isolate_btn)
		var exile_btn := Button.new()
		exile_btn.text = "Exilar"
		exile_btn.pressed.connect(_on_exile.bind(r))
		row.add_child(exile_btn)

	return row
