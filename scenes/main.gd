extends Control

## Camada visual da Fase 2: instancia SimGame, LÊ WorldState e desenha.
## Nada aqui vaza para dentro de sim/ — esta cena só chama métodos
## públicos de SimGame e lê campos de WorldState (ver CLAUDE.md, regra 1).

const OK_COLOR := Palette.TRUTH_CALM
const DOUBT_COLOR := Palette.TRUTH_DOUBTS
const KNOW_COLOR := Palette.TRUTH_KNOWS
const ISOLATED_COLOR := Palette.ISOLATED
const METER_GOOD := Palette.GOOD
const METER_WARN := Palette.WARN
const METER_BAD := Palette.BAD
const BG_COLOR := Palette.BG
const PANEL_COLOR := Palette.PANEL
const PIP_ON := Palette.WARN
const PIP_OFF := Palette.PANEL_RAISED
const DANGER_COLOR := Palette.BAD

const RES_GOOD_MIN := 50.0
const RES_WARN_MIN := 25.0
const SOCIAL_WARN_MIN := 35.0
const SOCIAL_BAD_MIN := 60.0

## Estratos do Poço, do topo ao fundo. "" = sem sistema de recurso (a Coroa).
## "group" agrupa vários andares sob um mesmo cabeçalho de estrato (Parte D:
## corte lateral com mais andares — ver docs/10 Parte D).
const STRATA := [
	{"sys": "", "title": "A Coroa", "tint": Palette.STRATUM_CROWN, "group": "A Coroa", "icon": "crown"},
	{"sys": "Comida", "title": "Fazendas", "tint": Palette.STRATUM_MEIOS, "group": "Os Meios", "icon": "wheat"},
	{"sys": "Água", "title": "Reservatório", "tint": Palette.STRATUM_MEIOS, "group": "Os Meios", "icon": "droplets"},
	{"sys": "Ar", "title": "Filtragem", "tint": Palette.STRATUM_MEIOS, "group": "Os Meios", "icon": "wind"},
	{"sys": "Energia", "title": "Gerador", "tint": Palette.STRATUM_ENTRANHAS, "group": "As Entranhas", "icon": "zap"},
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
var selected_sector: String = ""
var status_label: Label

func _ready() -> void:
	_build_ui()
	game = SimGame.new()
	s = game.new_game(randi())
	_render()

# ---------------------------------------------------------------- UI build

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	theme = UiTheme.build()

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
	for sys in Balance.SYSTEMS:
		_add_action_button("Reparar %s" % sys, _on_patch.bind(sys))
	_add_action_button("Acalmar", func(): _do(game.calm()))
	_add_free_button("Salvar", func(): _on_save())
	_add_free_button("Carregar", func(): _on_load())

	status_label = Label.new()
	status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	col.add_child(status_label)

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

func _on_patch(sys: String) -> void:
	_do(game.patch(sys))

func _on_upgrade(sys: String) -> void:
	game.upgrade(sys)
	_render()

func _on_select_sector(sys: String) -> void:
	selected_sector = sys
	selected_id = -1
	_render()

func _on_advance_turn() -> void:
	game.advance_turn()
	_render()

func _on_save() -> void:
	game.save_game()
	status_label.text = "Jogo salvo."

func _on_load() -> void:
	if game.load_game():
		s = game.s
		selected_id = -1
		_render()
		status_label.text = "Jogo carregado."
	else:
		status_label.text = "Nenhum save encontrado."

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
	meters_box.add_child(_build_meter("Peças", s.parts, false, Balance.UPGRADE_PARTS_COST))

	for c in suspicion_bar_holder.get_children():
		c.queue_free()
	suspicion_bar_holder.add_child(_build_meter("Suspeita", s.suspicion, true, 100.0))

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
	var last_group := ""
	for stratum in STRATA:
		var group: String = stratum["group"]
		if group != last_group:
			well_column.add_child(_build_stratum_header(group, stratum["tint"]))
			last_group = group
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

func _build_meter(label_text: String, value: float, inverted: bool, max_value: float = Balance.RES_MAX) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(90, 0)
	var name_label := Label.new()
	name_label.text = label_text
	box.add_child(name_label)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = max_value
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
	bar.max_value = 100.0
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
	var floor_ratio := clampf(s.martyr_floor / 100.0, 0.0, 1.0)
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

## Cabeçalho de estrato (Parte D): agrupa visualmente vários andares sob
## "Coroa / Os Meios / As Entranhas", preservando a legibilidade "num
## relance" do docs/05 mesmo com mais andares por estrato.
func _build_stratum_header(title: String, tint: Color) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.add_theme_constant_override("margin_left", 4)
	var label := Label.new()
	label.text = title.to_upper()
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", tint.lerp(Color.WHITE, 0.55))
	margin.add_child(label)
	return margin

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

	if sys == "":
		var title_label := Label.new()
		title_label.text = title
		title_label.custom_minimum_size = Vector2(170, 0)
		header.add_child(title_label)
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

	var title_btn := Button.new()
	title_btn.text = title
	title_btn.custom_minimum_size = Vector2(170, 0)
	title_btn.flat = selected_sector != sys
	title_btn.pressed.connect(_on_select_sector.bind(sys))
	header.add_child(title_btn)

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
	var icon := ""
	if not r.traits.is_empty():
		icon += "✦"
	if not s.bonded_with(r.id).is_empty():
		icon += "♥"
	btn.text = r.given_name.substr(0, 2) + ("\n" + icon if icon != "" else "")
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
	selected_sector = ""
	_render()

## Redesenha o painel de ação contextual do morador selecionado.
func _render_selection() -> void:
	for c in selection_content.get_children():
		c.queue_free()

	if selected_sector != "":
		_render_sector_selection(selected_sector)
		return

	var r: Resident = s.find_by_id(selected_id)
	if r == null:
		var hint := Label.new()
		hint.text = "Clique num morador ou num setor na coluna do Poço para ver detalhes e agir."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD
		selection_content.add_child(hint)
		return

	var name_label := Label.new()
	name_label.text = r.full_name()
	selection_content.add_child(name_label)

	var job_text := r.job if r.job != "" else "sobressalente"
	if r.stratum() != "":
		job_text += " — %s" % r.stratum()
	var info := Label.new()
	info.text = job_text
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	selection_content.add_child(info)

	var state_text := "sabe" if r.state == "sabe" else ("desconfia" if r.state == "desconfiada" else "tranquila")
	var state_label := Label.new()
	state_label.text = state_text + (" (isolada)" if r.isolated else "")
	state_label.add_theme_color_override("font_color", _truth_color(r))
	selection_content.add_child(state_label)

	var mood_label := Label.new()
	mood_label.text = "Humor: %s" % r.mood()
	mood_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	selection_content.add_child(mood_label)

	if not r.traits.is_empty():
		var trait_labels: Array[String] = []
		for t in r.traits:
			trait_labels.append(Traits.label(t))
		var traits_label := Label.new()
		traits_label.text = "Traços: %s" % ", ".join(trait_labels)
		traits_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		selection_content.add_child(traits_label)

	var bonded_ids := s.bonded_with(r.id)
	if not bonded_ids.is_empty():
		var bond_names: Array[String] = []
		for bid in bonded_ids:
			var other := s.find_by_id(bid)
			if other != null:
				bond_names.append(other.given_name)
		var bonds_label := Label.new()
		bonds_label.text = "Vínculos: %s" % ", ".join(bond_names)
		bonds_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		selection_content.add_child(bonds_label)

	var bio_label := Label.new()
	bio_label.text = Story.bio(s, r)
	bio_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	selection_content.add_child(bio_label)

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

## Painel de detalhe de um setor selecionado: detalhamento de produção
## (workers × rendimento − consumo, com os multiplicadores em destaque) e
## o botão de upgrade (Parte C). Reaproveita selection_content, o mesmo
## painel usado para o detalhe de morador.
func _render_sector_selection(sys: String) -> void:
	var title_label := Label.new()
	title_label.text = sys
	selection_content.add_child(title_label)

	var b := s.production_breakdown(sys)
	var lvl: int = s.sector_upgrades.get(sys, 0)

	var lvl_label := Label.new()
	lvl_label.text = "Upgrade: nível %d/%d" % [lvl, Balance.UPGRADE_MAX_LEVEL]
	lvl_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	selection_content.add_child(lvl_label)

	var breakdown_label := Label.new()
	breakdown_label.text = "%d trab. × %.1f rend. = %.1f bruto\n× energia %.2f × suspeita %.2f\n= %.1f líquido/turno\n(consumo/setor: %.1f)" % [
		b["workers"], b["yield_per_worker"], b["gross"], b["energy_mult"], b["sus_mult"], b["net_production"], b["consumption_share"],
	]
	breakdown_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	selection_content.add_child(breakdown_label)

	var upgrade_btn := Button.new()
	upgrade_btn.text = "Upgrade (%d peças)" % int(Balance.UPGRADE_PARTS_COST)
	upgrade_btn.disabled = s.attention <= 0 or s.parts < Balance.UPGRADE_PARTS_COST or lvl >= Balance.UPGRADE_MAX_LEVEL
	upgrade_btn.pressed.connect(_on_upgrade.bind(sys))
	selection_content.add_child(upgrade_btn)
