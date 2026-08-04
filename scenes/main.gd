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

## Estratos do Poço, do topo ao fundo. "" = sem sistema de recurso (a Coroa).
const STRATA := [
	{"sys": "", "title": "A Coroa", "tint": Color(0.11, 0.14, 0.20)},
	{"sys": "Comida", "title": "Os Meios — Fazendas", "tint": Color(0.11, 0.17, 0.13)},
	{"sys": "Ar", "title": "Os Meios — Filtragem", "tint": Color(0.11, 0.17, 0.13)},
	{"sys": "Energia", "title": "As Entranhas — Gerador", "tint": Color(0.20, 0.16, 0.10)},
]

var game: SimGame
var s: WorldState

var meters_box: HBoxContainer
var suspicion_bar_holder: VBoxContainer
var rebellion_bar_holder: VBoxContainer
var attention_pips: Array[ColorRect] = []
var attention_label: Label
var turn_label: Label
var log_label: RichTextLabel        # coluna esquerda: feed de micro-histórias (Parte B)
var well_column: VBoxContainer
var selection_panel: PanelContainer
var selection_content: VBoxContainer
var selected_id: int = -1
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

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 10)
	root_layout.add_child(mid)

	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.custom_minimum_size = Vector2(220, 0)
	mid.add_child(log_label)

	# --- eixo central (escada) + coluna do Poço ---
	var well_row := HBoxContainer.new()
	well_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well_row.size_flags_stretch_ratio = 3.0
	well_row.add_theme_constant_override("separation", 6)
	mid.add_child(well_row)

	var axis := ColorRect.new()
	axis.color = Color(0.35, 0.38, 0.45)
	axis.custom_minimum_size = Vector2(3, 0)
	axis.size_flags_vertical = Control.SIZE_EXPAND_FILL
	well_row.add_child(axis)

	var well_scroll := ScrollContainer.new()
	well_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well_row.add_child(well_scroll)
	well_column = VBoxContainer.new()
	well_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well_column.add_theme_constant_override("separation", 6)
	well_scroll.add_child(well_column)

	selection_panel = PanelContainer.new()
	selection_panel.custom_minimum_size = Vector2(200, 0)
	selection_panel.add_theme_stylebox_override("panel", _panel_style())
	mid.add_child(selection_panel)
	selection_content = VBoxContainer.new()
	selection_content.add_theme_constant_override("separation", 6)
	selection_panel.add_child(selection_content)

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
	_add_free_button("Salvar", func(): game.save_game())
	_add_free_button("Carregar", func(): _on_load())

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

## Botão que não depende de atenção restante (ex.: Salvar/Carregar).
func _add_free_button(label: String, on_press: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.pressed.connect(on_press)
	actions_box.add_child(b)

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

func _on_load() -> void:
	if game.load_game():
		s = game.s
		selected_id = -1
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

	log_label.clear()
	if s.story_log_lines.is_empty():
		log_label.append_text("O diário do Poço ainda está em branco.\n")
	for line in s.story_log_lines:
		log_label.append_text(line + "\n")

	for c in well_column.get_children():
		c.queue_free()
	for stratum in STRATA:
		well_column.add_child(_build_floor(stratum["sys"], stratum["title"], stratum["tint"]))
	well_column.add_child(_build_reserve_panel())

	_render_selection()

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

## Cor "de verdade" do morador (ignora isolamento — usada na borda da célula
## de um isolado, para que se veja o que ele sabe além do fato de estar isolado).
func _truth_color(r: Resident) -> Color:
	if r.state == "sabe":
		return KNOW_COLOR
	if r.state == "desconfiada":
		return DOUBT_COLOR
	return OK_COLOR

func _state_color(r: Resident) -> Color:
	if r.isolated:
		return ISOLATED_COLOR
	return _truth_color(r)

func _floor_style(tint: Color, crisis: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = tint.lerp(DANGER_COLOR, 0.35) if crisis else tint
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

## Um andar-setor da coluna do Poço. sys == "" monta a Coroa (sem recurso,
## só alerta da verdade + última linha do registro).
func _build_floor(sys: String, title: String, tint: Color) -> Control:
	var crisis: bool = sys != "" and s.res[sys] < RES_WARN_MIN
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _floor_style(tint, crisis))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	col.add_child(header)

	var title_label := Label.new()
	title_label.text = title
	title_label.custom_minimum_size = Vector2(170, 0)
	header.add_child(title_label)

	if sys == "":
		var knowers := s.count_state("sabe")
		var alert := Label.new()
		if knowers > 0:
			alert.text = "%d morador(es) sabem — aja" % knowers
			alert.add_theme_color_override("font_color", KNOW_COLOR)
		else:
			alert.text = "Tudo calmo."
			alert.add_theme_color_override("font_color", Color(0.6, 0.65, 0.6))
		header.add_child(alert)
		var crown_log := RichTextLabel.new()
		crown_log.bbcode_enabled = true
		crown_log.custom_minimum_size = Vector2(0, 110)
		for line in s.log_lines:
			crown_log.append_text(line + "\n")
		var log_scroll := ScrollContainer.new()
		log_scroll.custom_minimum_size = Vector2(0, 110)
		log_scroll.add_child(crown_log)
		col.add_child(log_scroll)
		return panel

	header.add_child(_build_meter(sys, s.res[sys], false))
	var stats := Label.new()
	stats.text = "trabalhadores: %d — líquido/turno: %+.1f" % [s.active_workers(sys), s.net_delta(sys)]
	header.add_child(stats)

	var cells := HFlowContainer.new()
	cells.add_theme_constant_override("h_separation", 4)
	cells.add_theme_constant_override("v_separation", 4)
	col.add_child(cells)
	for r in s.residents:
		if r.job == sys:
			cells.add_child(_build_cell(r))

	return panel

func _build_reserve_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	var col := VBoxContainer.new()
	panel.add_child(col)
	col.add_child(_section_title("Reserva (sem posto)"))
	var cells := HFlowContainer.new()
	cells.add_theme_constant_override("h_separation", 4)
	cells.add_theme_constant_override("v_separation", 4)
	col.add_child(cells)
	for r in s.residents:
		if r.job == "":
			cells.add_child(_build_cell(r))
	return panel

## Célula clicável de um morador, colorida pelo estágio de verdade.
## Isolados mantêm a cor de fundo neutra mas ganham uma borda com a cor
## "de verdade" — dá para ver estado E isolamento na mesma célula.
func _build_cell(r: Resident) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(34, 26)
	btn.text = r.given_name.substr(0, 2)
	var job_text := r.job if r.job != "" else "sobressalente"
	var state_text := "sabe" if r.state == "sabe" else ("desconfia" if r.state == "desconfiada" else "tranquila")
	btn.tooltip_text = "%s — %s — %s%s" % [r.given_name, job_text, state_text, " (isolada)" if r.isolated else ""]

	var style := StyleBoxFlat.new()
	style.bg_color = _state_color(r)
	if r.isolated:
		style.border_color = _truth_color(r)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
	if r.id == selected_id:
		style.border_color = Color(1, 1, 1)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
	btn.add_theme_stylebox_override("normal", style)
	btn.pressed.connect(_on_select_resident.bind(r))
	return btn

func _on_select_resident(r: Resident) -> void:
	selected_id = r.id
	_render()

## Redesenha o painel de ação contextual do morador selecionado.
func _render_selection() -> void:
	for c in selection_content.get_children():
		c.queue_free()

	var r: Resident = s.find_by_id(selected_id)
	if r == null:
		var hint := Label.new()
		hint.text = "Clique num morador na coluna do Poço para ver detalhes e agir."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD
		selection_content.add_child(hint)
		return

	var name_label := Label.new()
	name_label.text = r.given_name
	selection_content.add_child(name_label)

	var job_text := r.job if r.job != "" else "sobressalente"
	var info := Label.new()
	info.text = job_text
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	selection_content.add_child(info)

	var state_text := "sabe" if r.state == "sabe" else ("desconfia" if r.state == "desconfiada" else "tranquila")
	var state_label := Label.new()
	state_label.text = state_text + (" (isolada)" if r.isolated else "")
	state_label.add_theme_color_override("font_color", _truth_color(r))
	selection_content.add_child(state_label)

	if r.isolated:
		var reintegrate_btn := Button.new()
		reintegrate_btn.text = "Reintegrar"
		reintegrate_btn.disabled = s.attention <= 0
		reintegrate_btn.pressed.connect(_on_reintegrate.bind(r))
		selection_content.add_child(reintegrate_btn)
	else:
		var isolate_btn := Button.new()
		isolate_btn.text = "Isolar"
		isolate_btn.disabled = s.attention <= 0
		isolate_btn.pressed.connect(_on_isolate.bind(r))
		selection_content.add_child(isolate_btn)

	var exile_btn := Button.new()
	exile_btn.text = "Exilar"
	exile_btn.disabled = s.attention <= 0
	exile_btn.add_theme_stylebox_override("normal", _danger_style())
	exile_btn.pressed.connect(_on_exile.bind(r))
	selection_content.add_child(exile_btn)
