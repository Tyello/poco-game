extends Control
class_name WellAxis

## Moldura do Poço: casca externa + eixo central (escada) ligando os
## andares. Puro _draw(), sem asset ilustrado — dá a sensação de
## estrutura vertical e "arranha-céu invertido" (Fase 5, Parte B).

const STEP := 22.0

func _init() -> void:
	custom_minimum_size = Vector2(26, 0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if h <= 0.0:
		return
	# casca externa do Poço
	draw_rect(Rect2(1, 0, w - 2, h), Palette.HAIRLINE, false, 1.5)
	# eixo central (escada) ligando os andares
	var cx := w / 2.0
	draw_line(Vector2(cx, 6), Vector2(cx, h - 6), Palette.INK_FAINT, 2.0)
	var y := 10.0
	while y < h - 8.0:
		draw_line(Vector2(cx - 5, y), Vector2(cx + 5, y), Palette.INK_FAINT, 2.0)
		y += STEP
