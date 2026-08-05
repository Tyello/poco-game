extends RefCounted
class_name Icons

## Carrega os ícones SVG (Lucide, ISC — ver ui/CREDITS.md) em tempo de
## execução e tinge via `modulate`, sem passar pelo pipeline de import
## do editor. O stroke dos SVGs em ui/icons/ já está gravado em branco
## (#ffffff) — TextureRect.modulate multiplica por cima para colorir.

const DIR := "res://ui/icons/"

const NAMES := [
	"crown", "wheat", "droplets", "wind", "zap", "users",
	"triangle-alert", "heart", "sparkles", "shield", "shield-off",
	"skull", "save", "download",
]

static var _cache: Dictionary = {}

## Retorna uma ImageTexture rasterizada de `name` no tamanho `size` (px).
## Cacheia por (nome, tamanho) — o mesmo ícone no mesmo tamanho é pedido
## repetidas vezes a cada _render().
static func texture(icon_name: String, size: int = 16) -> ImageTexture:
	var key := "%s@%d" % [icon_name, size]
	if _cache.has(key):
		return _cache[key]
	var path := DIR + icon_name + ".svg"
	var svg_text := FileAccess.get_file_as_string(path)
	var img := Image.new()
	img.load_svg_from_string(svg_text, float(size) / 24.0)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

## Um TextureRect pronto, já tingido, do tamanho pedido.
static func rect(icon_name: String, color: Color, size: int = 16) -> TextureRect:
	var t := TextureRect.new()
	t.texture = texture(icon_name, size)
	t.modulate = color
	t.custom_minimum_size = Vector2(size, size)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t
