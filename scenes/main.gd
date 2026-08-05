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

const SECTOR_ICON := {"Ar": "wind", "Energia": "zap", "Comida": "wheat", "Água": "droplets"}

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

	var log_col := VBoxContainer.new()
	log_col.custom_minimum_size = Vector2(220, 0)
	log_col.add_theme_constant_override("separation", 6)
	mid.add_child(log_col)
	log_col.add_child(_section_title("Diário"))
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_col.add_child(log_label)

	# --- eixo central (escada) + coluna do Poço ---
	var well_row := HBoxContainer.new()
	well_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well_row.size_flags_stretch_ratio = 3.0
	well_row.add_theme_constant_override("separation", 6)
	mid.add_child(well_row)

	well_row.add_child(WellAxis.new())

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

	# --- toolbar de ações (ícone + rótulo), agrupada por função ---
	actions_box = HBoxContainer.new()
	actions_box.add_theme_constant_override("separation", 6)
	col.add_child(actions_box)
	for sys in Balance.SYSTEMS:
		_add_action_button("Reparar %s" % sys, SECTOR_ICON.get(sys, ""), _on_patch.bind(sys))
	_add_action_button("Acalmar", "shield", func(): _do(game.calm()))
	actions_box.add_child(_toolbar_separator())
	_add_free_button("Salvar", "save", func(): _on_save())
	_add_free_button("Carregar", "download", func(): _on_load())

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_box.add_child(spacer)

	# pips de atenção: claros, com o número ao lado (docs/05, Parte C)
	for i in range(Balance.ATTENTION_PER_TURN):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(12, 12)
		attention_pips.append(pip)
		actions_box.add_child(pip)
	attention_label = Label.new()
	attention_label.add_theme_font_override("font", UiTheme.mono_font())
	actions_box.add_child(attention_label)
	actions_box.add_child(_toolbar_separator())
	turn_label = Label.new()
	turn_label.add_theme_font_override("font", UiTheme.semibold_font())
	actions_box.add_child(turn_label)

	status_label = Label.new()
	status_label.add_theme_color_override("font_color", Palette.INK_FAINT)
	col.add_child(status_label)

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

## Monta um botão ícone + rótulo dentro de um HBoxContainer (Button não
## aceita ícone e texto juntos sem um ícone importado como Texture2D
## registrado no theme — mais simples e explícito montar na mão).
func _icon_button(label: String, icon_name: String) -> Button:
	var b := Button.new()
	b.text = label
	if icon_name != "":
		b.icon = Icons.texture(icon_name, 14)
		b.add_theme_constant_override("h_separation", 6)
	return b

func _add_action_button(label: String, icon_name: String, on_press: Callable) -> void:
	var b := _icon_button(label, icon_name)
	b.pressed.connect(on_press)
	actions_box.add_child(b)
	action_buttons.append(b)

## Botão que não depende de atenção restante (ex.: Salvar/Carregar).
func _add_free_button(label: String, icon_name: String, on_press: Callable) -> void:
	var b := _icon_button(label, icon_name)
	b.pressed.connect(on_press)
	actions_box.add_child(b)

func _toolbar_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = Palette.HAIRLINE
	sep.custom_minimum_size = Vector2(1, 20)
	return sep

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
	_flash_status("Jogo salvo.")

func _on_load() -> void:
	if game.load_game():
		s = game.s
		selected_id = -1
		_render()
		_flash_status("Jogo carregado.")
	else:
		_flash_status("Nenhum save encontrado.")

## Toast discreto: aparece, segura um instante, some — em vez de um texto
## que fica preso na tela. Restrição proposital (docs/11, Parte E).
func _flash_status(text: String) -> void:
	status_label.text = text
	status_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(status_label, "modulate:a", 1.0, 0.12)
	tw.tween_interval(1.6)
	tw.tween_property(status_label, "modulate:a", 0.0, 0.5)

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
		log_label.append_text("[i]O diário do Poço ainda está em branco.[/i]")
	for line in s.story_log_lines:
		log_label.append_text("[color=#%s]•[/color] %s\n" % [Palette.HAIRLINE.lightened(0.2).to_html(false), line])

	for c in well_column.get_children():
		c.queue_free()
	var last_group := ""
	for stratum in STRATA:
		var group: String = stratum["group"]
		if group != last_group:
			well_column.add_child(_build_stratum_header(group, stratum["tint"]))
			last_group = group
		well_column.add_child(_build_floor(stratum["sys"], stratum["title"], stratum["tint"], stratum["icon"]))
	well_column.add_child(_build_reserve_panel())

	well_column.modulate.a = 0.55
	var turn_tw := create_tween()
	turn_tw.tween_property(well_column, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)

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

const METER_BAR_HEIGHT := 10

## Barra de progresso com estilo consistente e cor por limiar aplicada na
## stylebox de preenchimento (não em modulate — modulate desbota também o
## fundo e o texto). Escala corretamente acima de 100 porque `max_value`
## define o teto do próprio ProgressBar, não um clamp visual solto.
func _meter_bar(value: float, max_value: float, inverted: bool) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = max_value
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, METER_BAR_HEIGHT)
	var fill := StyleBoxFlat.new()
	fill.bg_color = _meter_color(value, inverted)
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _build_meter(label_text: String, value: float, inverted: bool, max_value: float = Balance.RES_MAX) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(96, 0)
	box.add_theme_constant_override("separation", 3)
	var name_label := Label.new()
	name_label.text = label_text
	name_label.add_theme_color_override("font_color", Palette.INK_DIM)
	box.add_child(name_label)
	box.add_child(_meter_bar(value, max_value, inverted))
	var value_label := Label.new()
	value_label.text = "%d" % int(value)
	value_label.add_theme_font_override("font", UiTheme.mono_font())
	value_label.add_theme_color_override("font_color", _meter_color(value, inverted))
	box.add_child(value_label)
	return box

## Barra da Rebelião com a marca do piso permanente (martyr_floor).
func _build_rebellion_meter() -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(96, 0)
	box.add_theme_constant_override("separation", 3)
	var name_label := Label.new()
	name_label.text = "Rebelião"
	name_label.add_theme_color_override("font_color", Palette.INK_DIM)
	box.add_child(name_label)

	var bar_stack := Control.new()
	bar_stack.custom_minimum_size = Vector2(0, METER_BAR_HEIGHT)
	box.add_child(bar_stack)

	var bar := _meter_bar(s.rebellion, 100.0, true)
	bar.anchor_right = 1.0
	bar.anchor_bottom = 1.0
	bar_stack.add_child(bar)

	# marca do piso permanente de revolta (martyr_floor) — a barra nunca
	# volta a cair abaixo desta marca depois de um exílio.
	var floor_mark := ColorRect.new()
	floor_mark.color = Palette.SELECTED
	floor_mark.custom_minimum_size = Vector2(2, 0)
	floor_mark.anchor_top = 0.0
	floor_mark.anchor_bottom = 1.0
	var floor_ratio := clampf(s.martyr_floor / 100.0, 0.0, 1.0)
	floor_mark.anchor_left = floor_ratio
	floor_mark.anchor_right = floor_ratio
	bar_stack.add_child(floor_mark)

	var value_label := Label.new()
	value_label.text = "%d (piso: %d)" % [int(s.rebellion), int(s.martyr_floor)]
	value_label.add_theme_font_override("font", UiTheme.mono_font())
	value_label.add_theme_color_override("font_color", _meter_color(s.rebellion, true))
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

## Painel de andar: leve indicação de profundidade (borda interna hairline)
## e, em crise, um alarme inequívoco (borda vermelha grossa) — identificável
## em <1s, sem precisar ler números (docs/05, checklist Fase 5).
func _floor_style(tint: Color, crisis: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = tint.lerp(DANGER_COLOR, 0.45) if crisis else tint
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_color = DANGER_COLOR if crisis else Palette.HAIRLINE.lightened(0.05)
	style.border_width_left = 2 if crisis else 1
	style.border_width_right = 2 if crisis else 1
	style.border_width_top = 2 if crisis else 1
	style.border_width_bottom = 2 if crisis else 1
	style.content_margin_left = 12
	style.content_margin_right = 12
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

## Separador hairline entre o cabeçalho de um andar e o corpo (moradores/log) —
## dá a sensação de painel desenhado, não de retângulo chapado.
func _hairline() -> Control:
	var line := ColorRect.new()
	line.color = Palette.HAIRLINE
	line.custom_minimum_size = Vector2(0, 1)
	return line

## Um andar-setor da coluna do Poço. sys == "" monta a Coroa (sem recurso,
## só alerta da verdade + última linha do registro) — a "vitrine da mentira":
## o alerta de verdade e o topo do diário moram nela.
func _build_floor(sys: String, title: String, tint: Color, icon_name: String) -> Control:
	var crisis: bool = sys != "" and s.res[sys] < RES_WARN_MIN
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _floor_style(tint, crisis))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	col.add_child(header)
	header.add_child(Icons.rect(icon_name, Palette.INK, 18))

	if sys == "":
		var title_label := Label.new()
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.add_theme_color_override("font_color", Palette.SELECTED)
		title_label.custom_minimum_size = Vector2(150, 0)
		header.add_child(title_label)
		var knowers := s.count_state("sabe")
		var alert := HBoxContainer.new()
		alert.add_theme_constant_override("separation", 4)
		if knowers > 0:
			alert.add_child(Icons.rect("triangle-alert", KNOW_COLOR, 14))
			var alert_label := Label.new()
			alert_label.text = "%d morador(es) sabem — aja" % knowers
			alert_label.add_theme_color_override("font_color", KNOW_COLOR)
			alert.add_child(alert_label)
		else:
			var alert_label2 := Label.new()
			alert_label2.text = "Tudo calmo."
			alert_label2.add_theme_color_override("font_color", OK_COLOR)
			alert.add_child(alert_label2)
		header.add_child(alert)
		col.add_child(_hairline())
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
	title_btn.custom_minimum_size = Vector2(150, 0)
	title_btn.flat = selected_sector != sys
	title_btn.pressed.connect(_on_select_sector.bind(sys))
	header.add_child(title_btn)

	header.add_child(_build_meter(sys, s.res[sys], false))
	var stats := Label.new()
	stats.text = "trabalhadores: %d — líquido/turno: %+.1f" % [s.active_workers(sys), s.net_delta(sys)]
	stats.add_theme_color_override("font_color", Palette.INK_DIM)
	header.add_child(stats)

	if crisis:
		var crisis_tag := HBoxContainer.new()
		crisis_tag.add_theme_constant_override("separation", 4)
		var crisis_icon := Icons.rect("triangle-alert", DANGER_COLOR, 14)
		crisis_tag.add_child(crisis_icon)
		var crisis_label := Label.new()
		crisis_label.text = "CRISE"
		crisis_label.add_theme_color_override("font_color", DANGER_COLOR)
		crisis_tag.add_child(crisis_label)
		header.add_child(crisis_tag)
		_pulse(crisis_icon)

	col.add_child(_hairline())

	var cells := HFlowContainer.new()
	cells.add_theme_constant_override("h_separation", 5)
	cells.add_theme_constant_override("v_separation", 5)
	col.add_child(cells)
	for r in s.residents:
		if r.job == sys:
			cells.add_child(_build_cell(r))

	return panel

func _build_reserve_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.add_child(Icons.rect("users", Palette.INK_DIM, 16))
	header.add_child(_section_title("Reserva (sem posto)"))
	col.add_child(header)
	col.add_child(_hairline())
	var cells := HFlowContainer.new()
	cells.add_theme_constant_override("h_separation", 5)
	cells.add_theme_constant_override("v_separation", 5)
	col.add_child(cells)
	for r in s.residents:
		if r.job == "":
			cells.add_child(_build_cell(r))
	return panel

const CHIP_SIZE := 34

## Estilo circular (corner_radius = metade do tamanho) para o monograma
## do morador — "ficha limpa", não retângulo.
func _chip_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = CHIP_SIZE / 2
	style.corner_radius_top_right = CHIP_SIZE / 2
	style.corner_radius_bottom_left = CHIP_SIZE / 2
	style.corner_radius_bottom_right = CHIP_SIZE / 2
	if border_width > 0:
		style.border_color = border
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
	return style

## Pulso lento e contínuo (alarme de crise) — nunca pisca rápido, só
## respira. Criado de novo a cada _render(), então some sozinho quando o
## nó é destruído (sem tween pendurado).
func _pulse(control: CanvasItem) -> void:
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(control, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(control, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

## Micro-feedback de hover: leve escala num controle, sem depender de
## shaders. Usado nos chips de morador — resposta tátil discreta.
func _pop_scale(control: Control, target: float) -> void:
	if not is_instance_valid(control):
		return
	var tw := create_tween()
	tw.tween_property(control, "scale", Vector2(target, target), 0.1)

## Igual a _chip_style mas com tamanho arbitrário — usado no monograma
## maior da ficha-dossiê.
func _circle_style(size: int, bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = size / 2
	style.corner_radius_top_right = size / 2
	style.corner_radius_bottom_left = size / 2
	style.corner_radius_bottom_right = size / 2
	if border_width > 0:
		style.border_color = border
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
	return style

## Pílula de texto curto (estado, traço) — fundo colorido, cantos totalmente
## arredondados, padding horizontal folgado para não parecer um botão.
func _pill(text: String, bg: Color, fg: Color = Palette.INK) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", fg)
	lbl.add_theme_font_size_override("font_size", 12)
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	lbl.add_theme_stylebox_override("normal", style)
	return lbl

## Ficha clicável de um morador: monograma num círculo, colorido pelo
## estágio de verdade. Isolados mantêm a cor de fundo neutra mas ganham
## uma borda com a cor "de verdade" — dá para ver estado E isolamento na
## mesma ficha. Micro-indicadores de vínculo/traço ficam sobrepostos no
## canto inferior direito, sem atrapalhar o clique.
func _build_cell(r: Resident) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(CHIP_SIZE, CHIP_SIZE)

	var btn := Button.new()
	btn.anchor_right = 1.0
	btn.anchor_bottom = 1.0
	btn.text = r.given_name.substr(0, 2).to_upper()
	btn.add_theme_font_override("font", UiTheme.semibold_font())

	var job_text := r.job if r.job != "" else "sobressalente"
	var state_text := "sabe" if r.state == "sabe" else ("desconfia" if r.state == "desconfiada" else "tranquila")
	btn.tooltip_text = "%s — %s — %s%s" % [r.given_name, job_text, state_text, " (isolada)" if r.isolated else ""]

	var bg := _state_color(r)
	var border := _truth_color(r) if r.isolated else Palette.SELECTED
	var border_width := 2 if (r.isolated or r.id == selected_id) else 0
	btn.add_theme_stylebox_override("normal", _chip_style(bg, border, border_width))
	btn.add_theme_stylebox_override("hover", _chip_style(bg.lightened(0.15), border, maxi(border_width, 1)))
	btn.add_theme_stylebox_override("pressed", _chip_style(bg.darkened(0.15), border, border_width))
	btn.pressed.connect(_on_select_resident.bind(r))
	btn.pivot_offset = Vector2(CHIP_SIZE, CHIP_SIZE) / 2.0
	btn.mouse_entered.connect(_pop_scale.bind(btn, 1.12))
	btn.mouse_exited.connect(_pop_scale.bind(btn, 1.0))
	wrap.add_child(btn)

	if not s.bonded_with(r.id).is_empty():
		wrap.add_child(_badge("heart", Vector2(-13, -13)))
	if not r.traits.is_empty():
		wrap.add_child(_badge("sparkles", Vector2(-13, 2)))

	return wrap

## Micro-indicador (vínculo/traço) sobreposto no canto da ficha do morador —
## ignora o mouse para não atrapalhar o clique no monograma.
func _badge(icon_name: String, offset: Vector2) -> Control:
	var badge := Icons.rect(icon_name, Palette.SELECTED, 11)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.anchor_top = 1.0
	badge.anchor_bottom = 1.0
	badge.position = offset
	return badge

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

	# --- cabeçalho: monograma num círculo + nome + posto/estrato ---
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	selection_content.add_child(header)

	var monogram := Label.new()
	monogram.text = r.given_name.substr(0, 2).to_upper()
	monogram.custom_minimum_size = Vector2(44, 44)
	monogram.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monogram.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	monogram.add_theme_font_override("font", UiTheme.bold_font())
	monogram.add_theme_font_size_override("font_size", 16)
	monogram.add_theme_stylebox_override("normal", _circle_style(44, _state_color(r), Palette.SELECTED, 2))
	header.add_child(monogram)

	var name_col := VBoxContainer.new()
	name_col.add_theme_constant_override("separation", 2)
	header.add_child(name_col)
	var name_label := Label.new()
	name_label.text = r.full_name()
	name_label.add_theme_font_override("font", UiTheme.bold_font())
	name_label.add_theme_font_size_override("font_size", 16)
	name_col.add_child(name_label)

	var job_row := HBoxContainer.new()
	job_row.add_theme_constant_override("separation", 4)
	name_col.add_child(job_row)
	var job_text := r.job if r.job != "" else "sobressalente"
	if r.job != "" and SECTOR_ICON.has(r.job):
		job_row.add_child(Icons.rect(SECTOR_ICON[r.job], Palette.INK_DIM, 13))
	if r.stratum() != "":
		job_text += " — %s" % r.stratum()
	var info := Label.new()
	info.text = job_text
	info.add_theme_color_override("font_color", Palette.INK_DIM)
	job_row.add_child(info)

	# --- estado de verdade (pílula) + humor ---
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	selection_content.add_child(status_row)
	var state_text := "sabe" if r.state == "sabe" else ("desconfia" if r.state == "desconfiada" else "tranquila")
	status_row.add_child(_pill(state_text + (" · isolada" if r.isolated else ""), _truth_color(r)))
	var mood_label := Label.new()
	mood_label.text = "Humor: %s" % r.mood()
	mood_label.add_theme_color_override("font_color", Palette.INK_DIM)
	status_row.add_child(mood_label)

	if not r.traits.is_empty():
		selection_content.add_child(_hairline())
		selection_content.add_child(_section_title("Traços"))
		var traits_row := HFlowContainer.new()
		traits_row.add_theme_constant_override("h_separation", 4)
		traits_row.add_theme_constant_override("v_separation", 4)
		selection_content.add_child(traits_row)
		for t in r.traits:
			traits_row.add_child(_pill(Traits.label(t), Palette.PANEL_RAISED, Palette.INK))

	var bonded_ids := s.bonded_with(r.id)
	if not bonded_ids.is_empty():
		selection_content.add_child(_hairline())
		selection_content.add_child(_section_title("Vínculos"))
		var bonds_row := HFlowContainer.new()
		bonds_row.add_theme_constant_override("h_separation", 6)
		bonds_row.add_theme_constant_override("v_separation", 4)
		selection_content.add_child(bonds_row)
		for bid in bonded_ids:
			var other := s.find_by_id(bid)
			if other != null:
				var bond_label := Label.new()
				bond_label.text = other.given_name
				bond_label.add_theme_color_override("font_color", Palette.SELECTED)
				bond_label.add_theme_font_override("font", UiTheme.semibold_font())
				bonds_row.add_child(bond_label)

	selection_content.add_child(_hairline())
	var bio_label := Label.new()
	bio_label.text = Story.bio(s, r)
	bio_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	bio_label.add_theme_constant_override("line_spacing", 4)
	selection_content.add_child(bio_label)

	var actions_row := VBoxContainer.new()
	actions_row.add_theme_constant_override("separation", 4)
	selection_content.add_child(actions_row)

	if r.isolated:
		var reintegrate_btn := _icon_button("Reintegrar", "shield-off")
		reintegrate_btn.disabled = s.attention <= 0
		reintegrate_btn.pressed.connect(_on_reintegrate.bind(r))
		actions_row.add_child(reintegrate_btn)
	else:
		var isolate_btn := _icon_button("Isolar", "shield")
		isolate_btn.disabled = s.attention <= 0
		isolate_btn.pressed.connect(_on_isolate.bind(r))
		actions_row.add_child(isolate_btn)

	var exile_btn := _icon_button("Exilar", "skull")
	exile_btn.disabled = s.attention <= 0
	exile_btn.add_theme_stylebox_override("normal", _danger_style())
	exile_btn.add_theme_stylebox_override("hover", _danger_style())
	exile_btn.add_theme_color_override("font_color", Palette.SELECTED)
	exile_btn.pressed.connect(_on_exile.bind(r))
	actions_row.add_child(exile_btn)

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
