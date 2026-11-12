extends Control
## Fundo do ecrã. Em cada mundo usa assets/images/fundo_mundo<N>.png, se existir;
## senão fundo.png (a cobrir o ecrã); senão, um degradê suave com as cores do tema.

var _tex: Texture2D


func _ready() -> void:
	_tex = Game.texture("fundo")
	resized.connect(queue_redraw)


## w: índice do mundo, ou -1 para o fundo geral (menu, puzzle do dia).
func set_world(w: int) -> void:
	var t: Texture2D = Game.texture("fundo_mundo%d" % (w + 1)) if w >= 0 else null
	_tex = t if t else Game.texture("fundo")
	queue_redraw()


func _draw() -> void:
	if _tex:
		var ts := _tex.get_size()
		var k := maxf(size.x / ts.x, size.y / ts.y)
		var d := ts * k
		draw_texture_rect(_tex, Rect2((size - d) * 0.5, d), false)
		return
	var top := Color("d6e4f1")
	var bottom := Color("eef4f9")
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top, top, bottom, bottom]))
