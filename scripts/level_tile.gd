class_name LevelTile
extends BaseButton
## Quadrado de um nível no menu: bloqueado, disponível, atual ou resolvido (com estrelas).

const FONT := preload("res://assets/fonts/Baloo2-ExtraBold.ttf")

var number := 1
var state := "open"   # "locked", "open", "current", "done"
var stars := 0
var _pulse := 0.0


func setup(n: int, st: String, st_stars: int) -> void:
	number = n
	state = st
	stars = st_stars
	disabled = st == "locked"
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	set_process(st == "current")
	queue_redraw()


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


func _process(dt: float) -> void:
	_pulse = fmod(_pulse + dt * 1.4, TAU)
	queue_redraw()


func _draw() -> void:
	var C: Dictionary = Game.COLORS
	var accent: Color = Game.ANIMALS.coelho.color
	var down := is_pressed() and not disabled
	var lift := 0.0 if down or state == "locked" else 6.0
	var r := Rect2(Vector2(0, 0 if not down else 4), size - Vector2(0, 6))
	var rad := int(minf(size.x, size.y) * 0.3)
	var bg: Color = C.snow
	var fg: Color = C.ink
	match state:
		"locked":
			bg = Color(C.frost, 0.7)
			fg = C.frost_dark
		"done":
			bg = C.ink
			fg = C.snow
	# base: imagem ui_nivel / ui_nivel_feito / ui_nivel_fechado.png se existir
	var tex_name: String = {"locked": "ui_nivel_fechado", "done": "ui_nivel_feito"}.get(state, "ui_nivel")
	var tex_box := UITheme.tex_box(tex_name, 40, 0, 0)
	if tex_box:
		tex_box.modulate_color = Color(0.9, 0.9, 0.9) if down else Color.WHITE
		tex_box.draw(get_canvas_item(), Rect2(r.position, r.size + Vector2(0, 6)))
	else:
		if lift > 0.0:
			_box(Color(C.frost_dark if state != "done" else C.ink.darkened(0.45), 0.6), rad).draw(get_canvas_item(), Rect2(r.position + Vector2(0, lift), r.size))
		_box(bg, rad).draw(get_canvas_item(), r)
	if state == "current":
		var k := 0.5 + 0.5 * sin(_pulse)
		var ring := _box(Color(0, 0, 0, 0), rad + 6)
		ring.draw_center = false
		ring.set_border_width_all(5)
		ring.border_color = Color(accent, 0.55 + 0.45 * k)
		ring.draw(get_canvas_item(), r.grow(3.0 + 2.0 * k))
		fg = accent
	var c := r.get_center()
	if state == "locked" and Icons.has("cadeado"):
		Icons.draw_icon(self, "cadeado", c, minf(r.size.x, r.size.y) * 0.5, fg)
		return
	var fs := int(minf(r.size.x, r.size.y) * 0.46)
	var cy := c.y - (r.size.y * 0.09 if state == "done" else 0.0)
	var base := cy + (FONT.get_ascent(fs) - FONT.get_descent(fs)) * 0.5
	draw_string(FONT, Vector2(r.position.x, base), str(number), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, fg)
	if state == "done":
		var star := Game.texture("estrela")
		var ss := r.size.x * 0.2
		if star == null:
			var sf := int(ss * 0.95)
			draw_string(FONT, Vector2(r.position.x, r.end.y - ss * 0.45), "%d/3" % stars, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, sf, C.star)
			return
		for i in 3:
			var p := Vector2(c.x + (i - 1) * ss * 1.05, r.end.y - ss * 0.8)
			var tint := Color.WHITE if i < stars else Color(1, 1, 1, 0.22)
			Icons.draw_tex(self, star, p, ss, tint)


func _box(col: Color, rad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(rad)
	s.anti_aliasing = true
	return s
