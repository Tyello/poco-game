extends RefCounted
class_name UiTheme

## Monta o Theme do jogo em código (fontes, estilos de painel/botão/barra).
## Construído em código em vez de .tres à mão para não arriscar um
## resource-file inválido — o resultado é o mesmo: um único Theme do qual
## todo Control herda (aplicado uma vez na raiz, em main.gd).

const UNIT := 4 ## unidade-base do grid de espaçamento (múltiplos de 4)

static var _font_regular: FontFile
static var _font_semibold: FontFile
static var _font_bold: FontFile
static var _font_mono: FontFile

static func _load_fonts() -> void:
	if _font_regular != null:
		return
	_font_regular = load("res://ui/fonts/IBMPlexSans-Regular.ttf")
	_font_semibold = load("res://ui/fonts/IBMPlexSans-SemiBold.ttf")
	_font_bold = load("res://ui/fonts/IBMPlexSans-Bold.ttf")
	_font_mono = load("res://ui/fonts/IBMPlexMono-Regular.ttf")

static func mono_font() -> FontFile:
	_load_fonts()
	return _font_mono

static func semibold_font() -> FontFile:
	_load_fonts()
	return _font_semibold

static func bold_font() -> FontFile:
	_load_fonts()
	return _font_bold

static func panel_style(bg: Color = Palette.PANEL, radius: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_color = Palette.HAIRLINE
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.content_margin_left = UNIT * 3
	s.content_margin_right = UNIT * 3
	s.content_margin_top = UNIT * 2
	s.content_margin_bottom = UNIT * 2
	return s

static func button_style(bg: Color, border: Color = Palette.HAIRLINE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.border_color = border
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.content_margin_left = UNIT * 3
	s.content_margin_right = UNIT * 3
	s.content_margin_top = UNIT * 2
	s.content_margin_bottom = UNIT * 2
	return s

static func build() -> Theme:
	_load_fonts()
	var t := Theme.new()

	t.set_default_font(_font_regular)
	t.set_default_font_size(14)

	# --- Label ---
	t.set_font("font", "Label", _font_regular)
	t.set_font_size("font_size", "Label", 14)
	t.set_color("font_color", "Label", Palette.INK)

	# --- Button ---
	t.set_font("font", "Button", _font_semibold)
	t.set_font_size("font_size", "Button", 14)
	t.set_color("font_color", "Button", Palette.INK)
	t.set_color("font_hover_color", "Button", Palette.SELECTED)
	t.set_color("font_pressed_color", "Button", Palette.INK)
	t.set_color("font_disabled_color", "Button", Palette.INK_FAINT)
	t.set_stylebox("normal", "Button", button_style(Palette.PANEL_RAISED))
	t.set_stylebox("hover", "Button", button_style(Palette.PANEL_RAISED.lightened(0.12), Palette.INK_DIM))
	t.set_stylebox("pressed", "Button", button_style(Palette.PANEL_RAISED.darkened(0.15)))
	t.set_stylebox("disabled", "Button", button_style(Palette.PANEL, Palette.HAIRLINE))

	# --- PanelContainer ---
	t.set_stylebox("panel", "PanelContainer", panel_style())

	# --- ProgressBar ---
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Palette.PANEL_RAISED
	pb_bg.corner_radius_top_left = 3
	pb_bg.corner_radius_top_right = 3
	pb_bg.corner_radius_bottom_left = 3
	pb_bg.corner_radius_bottom_right = 3
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = Palette.GOOD
	pb_fill.corner_radius_top_left = 3
	pb_fill.corner_radius_top_right = 3
	pb_fill.corner_radius_bottom_left = 3
	pb_fill.corner_radius_bottom_right = 3
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fill)
	t.set_font("font", "ProgressBar", _font_mono)

	# --- RichTextLabel ---
	t.set_font("normal_font", "RichTextLabel", _font_regular)
	t.set_font_size("normal_font_size", "RichTextLabel", 13)
	t.set_color("default_color", "RichTextLabel", Palette.INK_DIM)

	return t
