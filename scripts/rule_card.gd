class_name RuleCard
extends Control
## Cartão de regra por cima do tabuleiro: o boneco, um mini-tabuleiro com o
## movimento (as casas para onde pode ir a partir do centro) e o nome com a comida.
## Sem frases: o movimento explica-se sozinho em qualquer língua.
## Para o gelo e o nevão, o mini-tabuleiro mostra a regra deles.

const FONT := preload("res://assets/fonts/Baloo2-ExtraBold.ttf")

var item := "ourico":
	set(v):
		item = v
		queue_redraw()
var compact := false:
	set(v):
		compact = v
		custom_minimum_size.y = 92.0 if v else 128.0
		queue_redraw()
## Animal que está a ser arrastado: o cartão ganha um contorno na cor dele.
var active := false:
	set(v):
		if v != active:
			active = v
			queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(0, 128)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var C: Dictionary = Game.COLORS
	var col: Color = Game.item_color(item)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("f2f6fa")
	bg.set_corner_radius_all(22)
	bg.anti_aliasing = true
	if active:
		bg.set_border_width_all(4)
		bg.border_color = col
	bg.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))

	var pad := 10.0
	var name_h := 0.0 if compact else 34.0
	var top_h := size.y - pad * 2 - name_h
	# boneco à esquerda, movimento à direita, os dois centrados no espaço
	var art := minf(top_h, (size.x - pad * 3) * 0.5)
	var grid := minf(top_h * 0.9, (size.x - pad * 3) * 0.5)
	var gap := maxf(4.0, (size.x - art - grid) / 3.0)
	var art_c := Vector2(gap + art * 0.5, pad + top_h * 0.5)
	var grid_r := Rect2(Vector2(gap * 2 + art, pad + (top_h - grid) * 0.5), Vector2(grid, grid))
	var tex := Game.texture(item)
	if tex:
		Icons.draw_tex(self, tex, art_c, art)
	_draw_rule(grid_r, col, C)

	if compact:
		return
	# nome, com a comida do animal ao lado
	var name := Game.animal_text(item, "NAME")
	var fs := 25
	var food := Game.texture("comida_" + item) if Game.ANIMALS.has(item) else null
	var food_s := 30.0 if food else 0.0
	var tw := FONT.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var total := tw + (food_s + 6.0 if food else 0.0)
	var x := (size.x - total) * 0.5
	var y := size.y - pad - name_h * 0.5
	var base := y + (FONT.get_ascent(fs) - FONT.get_descent(fs)) * 0.5
	draw_string(FONT, Vector2(x, base), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C.ink)
	if food:
		Icons.draw_tex(self, food, Vector2(x + tw + 6.0 + food_s * 0.5, y), food_s)


## Mini-tabuleiro: casas claras, o animal no centro (ponto escuro) e as casas
## onde pode pousar na cor dele.
func _draw_rule(r: Rect2, col: Color, C: Dictionary) -> void:
	match item:
		"gelo":
			_draw_ice(r, C)
			return
		"nevao":
			_draw_hidden(r, C)
			return
	var moves: Array = PuzzleState.MOVES.get(item, [])
	var n := 3
	for m in moves:
		n = maxi(n, 2 * maxi(absi(m.x), absi(m.y)) + 1)
	if item == "coruja":
		n = 5
		moves = []
		for k in range(1, 3):
			moves.append_array([Vector2i(k, 0), Vector2i(-k, 0), Vector2i(0, k), Vector2i(0, -k)])
	var cs := r.size.x / n
	var mid := n / 2
	for y in n:
		for x in n:
			var off := Vector2i(x - mid, y - mid)
			var cr := Rect2(r.position + Vector2(x, y) * cs, Vector2(cs, cs)).grow(-maxf(1.0, cs * 0.09))
			var fill := Color(C.frost, 0.55)
			if off in moves:
				fill = col
			_rounded(cr, fill, cs * 0.22)
			if off == Vector2i.ZERO:
				draw_circle(cr.get_center(), cs * 0.26, C.ink, true, -1.0, true)
	if item == "coruja":
		# a coruja vai até à borda: setas nas pontas
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var tip: Vector2 = r.get_center() + d * (r.size.x * 0.5 + cs * 0.12)
			var side := Vector2(-d.y, d.x) * cs * 0.22
			draw_colored_polygon(PackedVector2Array([tip + d * cs * 0.22, tip + side, tip - side]), col)


func _draw_ice(r: Rect2, C: Dictionary) -> void:
	# três casas em linha: entra, escorrega no gelo, sai na mesma direção
	var cs := r.size.x / 3
	var y := r.position.y + (r.size.y - cs) * 0.5
	for k in 3:
		var cr := Rect2(Vector2(r.position.x + k * cs, y), Vector2(cs, cs)).grow(-maxf(1.0, cs * 0.09))
		_rounded(cr, Color("bfe3f6") if k == 1 else Color(C.frost, 0.55), cs * 0.22)
	for k in 2:
		var c := Vector2(r.position.x + (k + 1) * cs, y + cs * 0.5)
		var h := cs * 0.34
		draw_colored_polygon(PackedVector2Array([c + Vector2(h, 0), c + Vector2(-h * 0.7, -h), c + Vector2(-h * 0.7, h)]), C.ink)


func _draw_hidden(r: Rect2, C: Dictionary) -> void:
	# uma fila de números das bordas, com o do meio tapado
	var cs := r.size.x / 3
	var y := r.position.y + (r.size.y - cs) * 0.5
	var fs := int(cs * 0.62)
	var labels := ["3", "", "2"]
	for k in 3:
		var cr := Rect2(Vector2(r.position.x + k * cs, y), Vector2(cs, cs)).grow(-maxf(1.0, cs * 0.09))
		if k == 1:
			var tex := Game.texture("numero_tapado")
			if tex:
				Icons.draw_tex(self, tex, cr.get_center(), cs * 1.1)
			continue
		var base := cr.get_center().y + (FONT.get_ascent(fs) - FONT.get_descent(fs)) * 0.5
		draw_string(FONT, Vector2(cr.position.x, base), labels[k], HORIZONTAL_ALIGNMENT_CENTER, cr.size.x, fs, C.ink_soft)


func _rounded(r: Rect2, col: Color, radius: float) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(int(radius))
	s.anti_aliasing = true
	s.draw(get_canvas_item(), r)
