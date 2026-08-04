extends Control

## Camada visual da Fase 2: instancia SimGame, LÊ WorldState e desenha.
## Nada aqui vaza para dentro de sim/ — esta cena só chama métodos
## públicos de SimGame e lê campos de WorldState (ver CLAUDE.md, regra 1).

const OK_COLOR := Color(0.30, 0.75, 0.40)
const DOUBT_COLOR := Color(0.85, 0.65, 0.15)
const KNOW_COLOR := Color(0.80, 0.20, 0.20)
const ISOLATED_COLOR := Color(0.55, 0.55, 0.60)
const METER_GOOD := Color(0.30, 0.75, 0.40)
const METER_WARN := Color(0.85, 0.65, 0.15)
const METER_BAD := Color(0.80, 0.20, 0.20)
const BG_COLOR := Color(0.08, 0.09, 0.11)
const PANEL_COLOR := Color(0.13, 0.14, 0.17)
const PIP_ON := Color(0.85, 0.80, 0.30)
const PIP_OFF := Color(0.30, 0.30, 0.33)
const DANGER_COLOR := Color(0.80, 0.20, 0.20)

const RES_GOOD_MIN := 50.0
const RES_WARN_MIN := 25.0
const SOCIAL_WARN_MIN := 35.0
const SOCIAL_BAD_MIN := 60.0

var game: SimGame
var s: WorldState

var meters_box: HBoxContainer
var suspicion_bar_holder: VBoxContainer
var rebellion_bar_holder: VBoxContainer
var attention_pips: Array[ColorRect] = []
var attention_label: Label
var turn_label: Label
var truth_banner: PanelContainer
var truth_banner_label: Label
var log_label: RichTextLabel
var residents_box: VBoxContainer
var actions_box: HBoxContainer
var advance_button: Button
var end_panel: PanelContainer
var end_label: RichTextLabel
var root_layout: VBoxContainer
var action_buttons: Array[Button] = []

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
	root_layout.add_theme_constant_override("separation", 12)
	add_child(root_layout)

	_build_hud_panel()
	truth_banner = _build_truth_banner()
	root_layout.add_child(truth_banner)

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

func _build_hud_panel() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	root_layout.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	# --- linha de ações + atenção/turno ---
	actions_box = HBoxContainer.new()
	actions_box.add_theme_constant_override("separation", 6)
	col.add_child(actions_box)
	_add_action_button("Reparar Ar", func(): _do(game.patch("Ar")))
	_add_action_button("Reparar Energia", func(): _do(game.patch("Energia")))
	_add_action_button("Reparar Comida", func(): _do(game.patch("Comida")))
	_add_action_button("Acalmar", func(): _do(game.calm()))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_box.add_child(spacer)

	for i in range(Balance.ATTENTION_PER_TURN):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 14)
		attention_pips.append(pip)
		actions_box.add_child(pip)
	attention_label = Label.new()
	actions_box.add_child(attention_label)
	turn_label = Label.new()
	actions_box.add_child(turn_label)

	# --- título + medidores de recursos ---
	col.add_child(_section_title("Recursos"))
	meters_box = HBoxContainer.new()
	meters_box.add_theme_constant_override("separation", 12)
	col.add_child(meters_box)

	# --- título + medidores sociais ---
	col.add_child(_section_title("Sociedade"))
	var social_box := HBoxContainer.new()
	social_box.add_theme_constant_override("separation", 12)
	col.add_child(social_box)
	suspicion_bar_holder = VBoxContainer.new()
	suspicion_bar_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	social_box.add_child(suspicion_bar_holder)
	rebellion_bar_holder = VBoxContainer.new()
	rebellion_bar_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	social_box.add_child(rebellion_bar_holder)

func _build_truth_banner() -> PanelContainer:
	var panel := PanelContainer.new()
	truth_banner_label = Label.new()
	truth_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(truth_banner_label)
	return panel

func _section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	return label

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _add_action_button(label: String, on_press: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.pressed.connect(on_press)
	actions_box.add_child(b)
	action_buttons.append(b)

func _danger_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.10, 0.10)
	style.border_color = DANGER_COLOR
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	return style

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
	for i in range(attention_pips.size()):
		attention_pips[i].color = PIP_ON if i < s.attention else PIP_OFF
	for b in action_buttons:
		b.disabled = s.attention <= 0

	for c in meters_box.get_children():
		c.queue_free()
	for sys in Balance.SYSTEMS:
		meters_box.add_child(_build_meter(sys, s.res[sys], false))

	for c in suspicion_bar_holder.get_children():
		c.queue_free()
	suspicion_bar_holder.add_child(_build_meter("Suspeita", s.suspicion, true))

	for c in rebellion_bar_holder.get_children():
		c.queue_free()
	rebellion_bar_holder.add_child(_build_rebellion_meter())

	var knowers := s.count_state("sabe")
	truth_banner.visible = knowers > 0
	if knowers > 0:
		truth_banner.add_theme_stylebox_override("panel", _danger_style())
		truth_banner_label.text = "%d morador(es) sabem — aja" % knowers
		truth_banner_label.add_theme_color_override("font_color", Color(1, 0.9, 0.9))

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

func _build_meter(label_text: String, value: float, inverted: bool) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(90, 0)
	var name_label := Label.new()
	name_label.text = label_text
	box.add_child(name_label)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = Balance.RES_MAX
	bar.value = value
	bar.show_percentage = false
	bar.modulate = _meter_color(value, inverted)
	box.add_child(bar)
	var value_label := Label.new()
	value_label.text = "%d" % int(value)
	box.add_child(value_label)
	return box

## Barra da Rebelião com a marca do piso permanente (martyr_floor).
func _build_rebellion_meter() -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(90, 0)
	var name_label := Label.new()
	name_label.text = "Rebelião"
	box.add_child(name_label)

	var bar_stack := Control.new()
	bar_stack.custom_minimum_size = Vector2(0, 24)
	box.add_child(bar_stack)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = Balance.RES_MAX
	bar.value = s.rebellion
	bar.show_percentage = false
	bar.modulate = _meter_color(s.rebellion, true)
	bar.anchor_right = 1.0
	bar.anchor_bottom = 1.0
	bar_stack.add_child(bar)

	var floor_mark := ColorRect.new()
	floor_mark.color = Color(1, 1, 1, 0.8)
	floor_mark.custom_minimum_size = Vector2(2, 0)
	floor_mark.anchor_top = 0.0
	floor_mark.anchor_bottom = 1.0
	var floor_ratio := clampf(s.martyr_floor / Balance.RES_MAX, 0.0, 1.0)
	floor_mark.anchor_left = floor_ratio
	floor_mark.anchor_right = floor_ratio
	bar_stack.add_child(floor_mark)

	var value_label := Label.new()
	value_label.text = "%d (piso: %d)" % [int(s.rebellion), int(s.martyr_floor)]
	box.add_child(value_label)
	return box

## Cor por limiar. `inverted` = true para medidores onde alto é ruim
## (Suspeita, Rebelião); false para recursos (alto é bom).
func _meter_color(value: float, inverted: bool) -> Color:
	if not inverted:
		if value > RES_GOOD_MIN:
			return METER_GOOD
		if value >= RES_WARN_MIN:
			return METER_WARN
		return METER_BAD
	else:
		if value < SOCIAL_WARN_MIN:
			return METER_GOOD
		if value <= SOCIAL_BAD_MIN:
			return METER_WARN
		return METER_BAD

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

	if r.isolated:
		var reintegrate_btn := Button.new()
		reintegrate_btn.text = "Reintegrar"
		reintegrate_btn.disabled = s.attention <= 0
		reintegrate_btn.pressed.connect(_on_reintegrate.bind(r))
		row.add_child(reintegrate_btn)
	else:
		var isolate_btn := Button.new()
		isolate_btn.text = "Isolar"
		isolate_btn.disabled = s.attention <= 0
		isolate_btn.pressed.connect(_on_isolate.bind(r))
		row.add_child(isolate_btn)
	var exile_btn := Button.new()
	exile_btn.text = "Exilar"
	exile_btn.disabled = s.attention <= 0
	exile_btn.add_theme_stylebox_override("normal", _danger_style())
	exile_btn.pressed.connect(_on_exile.bind(r))
	row.add_child(exile_btn)

	return row
