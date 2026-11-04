class_name RoundButton
extends BaseButton
## Botão redondo com ícone (imagem ou vetorial) e, opcionalmente, um contador.

@export var icon_name := "":
	set(v):
		icon_name = v
		queue_redraw()
@export var primary := false:
	set(v):
		primary = v
		queue_redraw()
## Número no círculo vermelho do canto. -1 esconde.
@export var badge := -1:
	set(v):
		badge = v
		queue_redraw()

const FONT := preload("res://assets/fonts/Baloo2-ExtraBold.ttf")


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var C: Dictionary = Game.COLORS
	var d := minf(size.x, size.y)
	var c := size * 0.5
	var r := d * 0.5 - 4.0
	var down := is_pressed() and not disabled
	var lift := 0.0 if down else d * 0.05
	var bg: Color = C.ink if primary else C.snow
	var fg: Color = C.snow if primary else C.ink
	var a := 0.45 if disabled else 1.0
	if is_hovered() and not disabled and not down:
		bg = bg.lightened(0.08) if primary else bg.darkened(0.02)
	var top := c + Vector2(0, d * 0.03 if down else 0.0)
	# base: imagem ui_redondo(_escuro).png se existir; senão círculo com sombra
	var base_tex := Game.texture("ui_redondo_escuro" if primary else "ui_redondo")
	if base_tex:
		var k := 0.9 if down else (1.06 if is_hovered() and not disabled else 1.0)
		Icons.draw_tex(self, base_tex, top, d, Color(k, k, k, a))
	else:
		draw_circle(c + Vector2(0, lift), r, Color(C.frost_dark if not primary else C.ink.darkened(0.4), 0.55 * a), true, -1.0, true)
		draw_circle(top, r, Color(bg, a), true, -1.0, true)
	Icons.draw_icon(self, icon_name, top, d * 0.5, Color(fg, a))
	if badge >= 0:
		var bc := c + Vector2(r * 0.72, -r * 0.72)
		var br := maxf(d * 0.17, 18.0)
		draw_circle(bc, br + 3.0, C.sky, true, -1.0, true)
		draw_circle(bc, br, Color(C.bad, 1.0 if badge > 0 else 0.5), true, -1.0, true)
		var fs := int(br * 1.25)
		var base := bc.y + (FONT.get_ascent(fs) - FONT.get_descent(fs)) * 0.5
		draw_string(FONT, Vector2(bc.x - br, base), str(badge), HORIZONTAL_ALIGNMENT_CENTER, br * 2, fs, Color.WHITE)
