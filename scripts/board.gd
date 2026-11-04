class_name Board
extends Control
## Desenha o tabuleiro e trata do toque/arrasto.

signal changed
signal path_completed(animal_type: String)
signal solved

const FONT := preload("res://assets/fonts/Baloo2-Bold.ttf")

var st: PuzzleState
var cell := 64.0
var hdr := 40.0
var origin := Vector2.ZERO

var _tex := {}
var _snow_box: StyleBoxFlat
var _rock_box: StyleBoxFlat
var _card_box: StyleBoxFlat
var _pill_box: StyleBoxFlat
var _bad_box: StyleBoxFlat

var _press_cell := Vector2i(-1, -1)
var _press_action := ""
var _moved := false
var _last_pos := Vector2.ZERO

var _bounce := {}          # tipo -> 0..1
var _flash_cell := Vector2i(-1, -1)
var _flash_t := 0.0
var win_anim := -1.0:
	set(v):
		win_anim = v
		_win_sounds()
		queue_redraw()
var _win_total := 0
var _win_played := 0


func setup(state: PuzzleState) -> void:
	st = state
	win_anim = -1.0
	_bounce.clear()
	_flash_t = 0.0
	for a in st.animals:
		var t: String = a.type
		_tex[t] = Game.texture(t)
		_tex["comida_" + t] = Game.texture("comida_" + t)
		_tex["pegada_" + t] = Game.texture("pegada_" + t)
	_tex["rocha"] = Game.texture("rocha")
	_layout()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()
		queue_redraw()


func _layout() -> void:
	if st == null:
		return
	var head := 0.62
	cell = floorf(minf(minf(size.x / (st.width + head), size.y / (st.height + head)), 132.0))
	hdr = cell * head
	var grid := Vector2(cell * st.width, cell * st.height)
	origin.x = maxf(hdr, (size.x - grid.x) * 0.5)
	origin.y = (size.y - grid.y - hdr) * 0.5 + hdr
	var C: Dictionary = Game.COLORS
	_snow_box = _box(C.snow, cell * 0.2, Color(C.frost_dark, 0.55), cell * 0.05)
	_rock_box = _box(Color(C.frost, 0.55), cell * 0.2, Color(0, 0, 0, 0), 0)
	_card_box = _box(Color(C.snow, 0.5), cell * 0.32, Color(C.frost_dark, 0.35), cell * 0.06)
	_pill_box = _box(Color(C.ok, 0.14), hdr * 0.4, Color(0, 0, 0, 0), 0)
	_bad_box = _box(Color(C.bad, 0.12), hdr * 0.4, Color(0, 0, 0, 0), 0)


func _box(bg: Color, radius: float, shadow: Color, off: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(radius))
	s.shadow_color = shadow
	s.shadow_size = 1 if shadow.a > 0 else 0
	s.shadow_offset = Vector2(0, off)
	s.anti_aliasing = true
	return s


func center_of(c: Vector2i) -> Vector2:
	return origin + (Vector2(c) + Vector2(0.5, 0.5)) * cell


func cell_at(pos: Vector2, strict: bool) -> Vector2i:
	var local := (pos - origin) / cell
	var c := Vector2i(floori(local.x), floori(local.y))
	if not st.in_bounds(c):
		return Vector2i(-1, -1)
	if strict and pos.distance_to(center_of(c)) > cell * 0.46:
		return Vector2i(-1, -1)
	return c


# ---------- entrada ----------

func _gui_input(e: InputEvent) -> void:
	if st == null or win_anim >= 0.0:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_on_press(e.position)
		else:
			_on_release()
		accept_event()
	elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_on_drag(e.position)
		accept_event()


func _on_press(pos: Vector2) -> void:
	_press_cell = cell_at(pos, false)
	_moved = false
	_last_pos = pos
	_press_action = st.press(_press_cell)
	if _press_action == "drag":
		changed.emit()
	queue_redraw()


func _on_drag(pos: Vector2) -> void:
	# percorre o segmento em passos pequenos para não saltar casas em gestos rápidos
	var steps := maxi(1, ceili(_last_pos.distance_to(pos) / (cell * 0.2)))
	for i in range(1, steps + 1):
		var p := _last_pos.lerp(pos, float(i) / steps)
		var c := cell_at(p, true)
		if c.x < 0:
			continue
		if c != _press_cell:
			_moved = true
		if _press_action != "drag":
			continue
		var t := st.active
		var r := st.drag(c)
		if r == "":
			continue
		match r:
			"step":
				Sfx.step(t, st.paths[t].size())
			"back":
				Sfx.play("passo_voltar")
			"complete":
				Sfx.step(t, st.paths[t].size())
				Sfx.play("chegou")
				_bounce[t] = 1.0
				set_process(true)
				path_completed.emit(t)
		changed.emit()
		queue_redraw()
	_last_pos = pos


func _on_release() -> void:
	if _press_action == "mark" and not _moved:
		st.toggle_mark(_press_cell)
		Sfx.play("marca", 1.0 if st.marks.has(_press_cell) else 0.85)
		changed.emit()
	st.release()
	_press_action = ""
	changed.emit()
	queue_redraw()
	if st.is_solved():
		solved.emit()


# ---------- animações ----------

## Na animação de vitória, cada pegada que salta toca uma nota a subir
## (no máximo umas 10, para não ficar uma metralhadora de sons).
func _win_sounds() -> void:
	if win_anim < 0.0 or _win_total == 0:
		return
	var reached := mini(int(win_anim * (_win_total + 4)), _win_total)
	var every := maxi(1, ceili(_win_total / 10.0))
	while _win_played < reached:
		if _win_played % every == 0:
			Sfx.note(int(8.0 * _win_played / _win_total))
		_win_played += 1


func flash(c: Vector2i) -> void:
	_flash_cell = c
	_flash_t = 1.0
	set_process(true)


func play_win() -> Tween:
	_win_total = 0
	_win_played = 0
	for a in st.animals:
		_win_total += maxi(0, st.paths[a.type].size() - 2)
	win_anim = 0.0
	var tw := create_tween()
	tw.tween_property(self, "win_anim", 1.0, 1.3).set_trans(Tween.TRANS_SINE)
	return tw


func _process(dt: float) -> void:
	var busy := false
	for t in _bounce.keys():
		_bounce[t] -= dt * 2.2
		if _bounce[t] <= 0.0:
			_bounce.erase(t)
		else:
			busy = true
	if _flash_t > 0.0:
		_flash_t -= dt * 0.7
		busy = true
	queue_redraw()
	if not busy:
		set_process(false)


# ---------- desenho ----------

func _draw() -> void:
	if st == null:
		return
	var C: Dictionary = Game.COLORS
	var grid := Vector2(cell * st.width, cell * st.height)
	var pad := cell * 0.14
	_card_box.draw(get_canvas_item(), Rect2(origin - Vector2(pad, pad), grid + Vector2(pad, pad) * 2))
	_draw_counters()

	var gap := maxf(2.0, cell * 0.05)
	for y in st.height:
		for x in st.width:
			var c := Vector2i(x, y)
			var r := Rect2(origin + Vector2(c) * cell, Vector2(cell, cell)).grow(-gap)
			if st.rocks.has(c):
				_rock_box.draw(get_canvas_item(), r)
				_draw_tex(_tex.rocha, center_of(c), cell * 0.78)
			else:
				_snow_box.draw(get_canvas_item(), r)
			if st.marks.has(c):
				var k := cell * 0.16
				var m := center_of(c)
				var col := Color(C.ink_soft, 0.5)
				draw_line(m - Vector2(k, k), m + Vector2(k, k), col, cell * 0.06, true)
				draw_line(m + Vector2(-k, k), m + Vector2(k, -k), col, cell * 0.06, true)

	if _flash_t > 0.0 and _flash_cell.x >= 0:
		var fr := Rect2(origin + Vector2(_flash_cell) * cell, Vector2(cell, cell)).grow(-gap)
		var fb := _box(Color(C.ok, 0.35 * _flash_t), cell * 0.2, Color(0, 0, 0, 0), 0)
		fb.draw(get_canvas_item(), fr)

	for a in st.animals:
		_draw_trail(a.type)
	_draw_givens_and_paws()
	for a in st.animals:
		_draw_animal(a)

	if st.active != "":
		var col: Color = Game.ANIMALS[st.active].color
		draw_arc(center_of(st.tip_of(st.active)), cell * 0.44, 0.0, TAU, 40, Color(col, 0.7), cell * 0.05, true)
		for c in st.valid_targets(st.active):
			draw_circle(center_of(c), cell * 0.09, Color(col, 0.55), true, -1.0, true)


func _draw_counters() -> void:
	var C: Dictionary = Game.COLORS
	var fs := int(clampf(cell * 0.42, 22.0, 44.0))
	var strict := st.all_complete()
	for x in st.width:
		var r := Rect2(origin.x + x * cell, origin.y - hdr - cell * 0.1, cell, hdr)
		_counter(r, st.col_count(x), st.col_targets[x], fs, C, strict)
	for y in st.height:
		var r := Rect2(origin.x - hdr - cell * 0.1, origin.y + y * cell, hdr, cell)
		_counter(r, st.row_count(y), st.row_targets[y], fs, C, strict)


## strict: todos os animais chegaram à comida, por isso qualquer diferença é erro.
func _counter(r: Rect2, cur: int, target: int, fs: int, C: Dictionary, strict: bool) -> void:
	var col: Color = C.ink
	var s := minf(r.size.x, r.size.y) * 0.86
	var pill := Rect2(r.get_center() - Vector2(s, s) * 0.5, Vector2(s, s))
	if cur == target:
		col = C.ok
		_pill_box.draw(get_canvas_item(), pill)
	elif cur > target or strict:
		col = C.bad
		_bad_box.draw(get_canvas_item(), pill)
	var base := r.get_center().y + (FONT.get_ascent(fs) - FONT.get_descent(fs)) * 0.5
	draw_string(FONT, Vector2(r.position.x, base), str(target), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, col)


func _trail_points(t: String) -> PackedVector2Array:
	var p: Array = st.paths[t]
	var pts := PackedVector2Array()
	for i in p.size():
		var b := center_of(p[i])
		if i > 0 and t == "coelho":
			# salto: um arco baixo, sempre para cima (ou para a esquerda), dentro das casas
			var a := center_of(p[i - 1])
			var d := (b - a).normalized()
			var n := Vector2(-d.y, d.x)
			if n.y > 0.0 or (is_zero_approx(n.y) and n.x > 0.0):
				n = -n
			var ctrl := (a + b) * 0.5 + n * cell * 0.36
			for k in range(1, 12):
				var u := k / 12.0
				pts.append(a.lerp(ctrl, u).lerp(ctrl.lerp(b, u), u))
		pts.append(b)
	return pts


## Rasto: uma faixa suave da cor do animal e, por cima, pontinhos espaçados,
## como um trilho na neve. As pegadas são desenhadas depois, por cima.
func _draw_trail(t: String) -> void:
	var p: Array = st.paths[t]
	if p.size() < 2:
		return
	var col: Color = Game.ANIMALS[t].color
	var pts := _trail_points(t)
	var w := cell * 0.2
	var soft := Color(col.lerp(Color.WHITE, 0.55), 0.55)
	draw_polyline(pts, soft, w, true)
	for q in [pts[0], pts[pts.size() - 1]]:
		draw_circle(q, w * 0.5, soft, true, -1.0, true)
	# pontinhos a cada ~0,2 casa ao longo do rasto
	var step := cell * 0.2
	var carry := step * 0.5
	var dot := Color(col, 0.5)
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		var pos := carry
		while pos < seg:
			draw_circle(a.lerp(b, pos / seg), cell * 0.03, dot, true, -1.0, true)
			pos += step
		carry = pos - seg


func _draw_givens_and_paws() -> void:
	var order := 0
	var total := 0
	for a in st.animals:
		total += maxi(0, st.paths[a.type].size() - 2)
	var warn := st.all_complete()
	for g in st.givens:
		var t: String = st.givens[g]
		if not (g in st.paths[t]):
			var col: Color = Game.ANIMALS[t].color
			var ring: Color = Game.COLORS.bad if warn else Color(col, 0.5)
			draw_arc(center_of(g), cell * 0.36, 0.0, TAU, 40, ring, cell * 0.045, true)
			_draw_tex(_tex["pegada_" + t], center_of(g), cell * 0.5, 0.0, Color(col, 0.55))
	for a in st.animals:
		var t: String = a.type
		var p: Array = st.paths[t]
		var col: Color = Game.ANIMALS[t].color
		for i in range(1, p.size() - 1):
			var d := Vector2(p[i] - p[i - 1]).normalized()
			var ang := atan2(d.x, -d.y)
			var s := cell * 0.5
			if win_anim >= 0.0:
				var phase := win_anim * (total + 4) - order
				s *= 1.0 + 0.45 * maxf(0.0, sin(clampf(phase, 0.0, 1.0) * PI))
			_draw_tex(_tex["pegada_" + t], center_of(p[i]), s, ang, col)
			if st.givens.has(p[i]):
				draw_arc(center_of(p[i]), cell * 0.36, 0.0, TAU, 40, Color(col, 0.35), cell * 0.03, true)
			order += 1


func _draw_animal(a: Dictionary) -> void:
	var t: String = a.type
	var p: Array = st.paths[t]
	var col: Color = Game.ANIMALS[t].color
	var done := st.is_complete(t)
	# toca: só se vê depois de o animal sair dela (buraco escuro com borda de neve)
	if p.size() > 1:
		var den := center_of(a.den) + Vector2(0, cell * 0.08)
		_ellipse(den, cell * 0.3, 0.62, Color(col, 0.22))
		_ellipse(den + Vector2(0, cell * 0.03), cell * 0.2, 0.55, Color(col.darkened(0.6), 0.6))
		draw_arc(den, cell * 0.3, PI * 1.1, PI * 1.9, 16, Color(col, 0.6), cell * 0.04, true)
	# comida: num círculo da cor do animal, para se ver de quem é
	var food := center_of(a.food)
	draw_circle(food, cell * 0.42, Color(col, 0.14), true, -1.0, true)
	draw_arc(food, cell * 0.42, 0.0, TAU, 40, Color(col, 0.75 if not done else 0.35), cell * 0.04, true)
	if done:
		_draw_tex(_tex["comida_" + t], food + Vector2(cell * 0.22, cell * 0.2), cell * 0.42)
	else:
		_draw_tex(_tex["comida_" + t], food, cell * 0.64)
	# animal: segue a ponta do caminho, com uma sombra suave por baixo
	var tip := center_of(p.back())
	var b: float = _bounce.get(t, 0.0)
	var lift := -sin(b * PI) * cell * 0.22
	if win_anim >= 0.0:
		lift -= sin(clampf(win_anim * 2.0 - 1.0, 0.0, 1.0) * PI * 2.0) * cell * 0.12
	var shrink := 1.0 + lift / (cell * 0.5)
	_ellipse(tip + Vector2(0, cell * 0.33), cell * 0.27 * shrink, 0.3, Color(Game.COLORS.ink, 0.16 * shrink))
	_draw_tex(_tex[t], tip + Vector2(0, lift - cell * 0.02), cell * 0.86)


func _ellipse(c: Vector2, r: float, squash: float, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, squash))
	draw_circle(Vector2.ZERO, r, col, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)


func _draw_tex(tex: Texture2D, center: Vector2, s: float, ang := 0.0, mod := Color.WHITE) -> void:
	if tex == null:
		return
	draw_set_transform(center, ang)
	draw_texture_rect(tex, Rect2(-s * 0.5, -s * 0.5, s, s), false, mod)
	draw_set_transform(Vector2.ZERO)
