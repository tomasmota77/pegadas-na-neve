class_name StarRow
extends Control
## Três estrelas (assets/images/estrela.png); as ganhas aparecem uma a uma com um salto.
## Sem a imagem, mostra o texto "2/3 estrelas".

const FONT := preload("res://assets/fonts/Baloo2-ExtraBold.ttf")

var filled := 0
var _t := 0.0


func play(n: int) -> void:
	filled = n
	_t = 0.0
	set_process(true)
	queue_redraw()


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()
	if _t > 1.6:
		set_process(false)


func _draw() -> void:
	var tex := Game.texture("estrela")
	if tex == null:
		var fs := int(size.y * 0.42)
		var base := size.y * 0.5 + (FONT.get_ascent(fs) - FONT.get_descent(fs)) * 0.5
		draw_string(FONT, Vector2(0, base), "%d/3 estrelas" % filled, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Game.COLORS.star.darkened(0.15))
		return
	var s := minf(size.y, size.x / 3.6)
	for i in 3:
		var big := i == 1
		var k := s * (1.0 if big else 0.82)
		var c := Vector2(size.x * 0.5 + (i - 1) * s * 1.15, size.y * 0.5 + (0.0 if big else s * 0.12))
		var pop := 0.0
		if i < filled:
			var local := clampf((_t - 0.25 - i * 0.28) / 0.35, 0.0, 1.0)
			pop = local * (1.0 + 0.3 * sin(local * PI))
		# vazia: a mesma estrela, cinzenta e transparente
		draw_texture_rect(tex, Rect2(c - Vector2(k, k) * 0.5, Vector2(k, k)), false, Color(0.55, 0.62, 0.72, 0.35))
		if pop > 0.0:
			var kk := k * pop
			draw_texture_rect(tex, Rect2(c - Vector2(kk, kk) * 0.5, Vector2(kk, kk)), false)
