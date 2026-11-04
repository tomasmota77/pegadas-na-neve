class_name UITheme
extends RefCounted
## Constrói o tema da interface (cores, fontes, botões, painéis).
## Variações de tipo: PrimaryButton, LevelButton, LevelButtonDone, IconButton,
## Card, Chip, Sheet, Title, H2, Muted, Small.

const FONT_MEDIUM := preload("res://assets/fonts/Baloo2-Medium.ttf")
const FONT_BOLD := preload("res://assets/fonts/Baloo2-Bold.ttf")
const FONT_XBOLD := preload("res://assets/fonts/Baloo2-ExtraBold.ttf")

const SIZE_TITLE := 76
const SIZE_H2 := 42
const SIZE_BODY := 30
const SIZE_SMALL := 24


static func build() -> Theme:
	var C: Dictionary = Game.COLORS
	var th := Theme.new()
	th.default_font = FONT_MEDIUM
	th.default_font_size = SIZE_BODY

	# Texto
	th.set_color("font_color", "Label", C.ink)
	for v in [["Title", FONT_XBOLD, SIZE_TITLE, C.ink], ["H2", FONT_BOLD, SIZE_H2, C.ink],
			["Muted", FONT_MEDIUM, SIZE_BODY, C.ink_soft], ["Small", FONT_MEDIUM, SIZE_SMALL, C.ink_soft]]:
		th.set_type_variation(v[0], "Label")
		th.set_font("font", v[0], v[1])
		th.set_font_size("font_size", v[0], v[2])
		th.set_color("font_color", v[0], v[3])
	th.set_constant("line_spacing", "Title", -34)
	th.set_color("default_color", "RichTextLabel", C.ink)
	th.set_font("normal_font", "RichTextLabel", FONT_MEDIUM)
	th.set_font("bold_font", "RichTextLabel", FONT_BOLD)
	th.set_font_size("normal_font_size", "RichTextLabel", SIZE_BODY)
	th.set_font_size("bold_font_size", "RichTextLabel", SIZE_BODY)

	# Botões
	_button(th, "Button", C.snow, C.ink, 28, C.frost_dark)
	th.set_type_variation("PrimaryButton", "Button")
	_button(th, "PrimaryButton", C.ink, C.snow, 32, Color(C.ink, 0.35))
	th.set_type_variation("LevelButton", "Button")
	_button(th, "LevelButton", C.snow, C.ink, 48, C.frost_dark)
	th.set_type_variation("LevelButtonDone", "Button")
	_button(th, "LevelButtonDone", C.ink, C.snow, 48, Color(C.ink, 0.35))
	th.set_type_variation("IconButton", "Button")
	_button(th, "IconButton", C.snow, C.ink, 40, C.frost_dark)
	for v in ["Button", "PrimaryButton", "LevelButton", "LevelButtonDone", "IconButton"]:
		th.set_font("font", v, FONT_BOLD)
		th.set_font_size("font_size", v, SIZE_BODY)
	th.set_font_size("font_size", "LevelButton", SIZE_H2)
	th.set_font_size("font_size", "LevelButtonDone", SIZE_H2)
	th.set_constant("h_separation", "Button", 12)
	th.set_constant("icon_max_width", "Button", 44)
	th.set_constant("icon_max_width", "IconButton", 48)

	# Painéis
	th.set_stylebox("panel", "PanelContainer", _box(C.snow, 40, 32, 28, C.frost_dark))
	th.set_type_variation("Card", "PanelContainer")
	th.set_stylebox("panel", "Card", _box(Color(C.snow, 0.72), 40, 32, 28, Color(C.frost_dark, 0.5)))
	th.set_type_variation("Chip", "PanelContainer")
	th.set_stylebox("panel", "Chip", _box(C.snow, 40, 20, 8, Color(C.frost_dark, 0.6)))
	th.set_type_variation("Sheet", "PanelContainer")
	var sheet := _box(C.snow, 48, 48, 40, Color(0, 0, 0, 0))
	sheet.corner_radius_bottom_left = 0
	sheet.corner_radius_bottom_right = 0
	th.set_stylebox("panel", "Sheet", sheet)

	# Barra de scroll discreta
	var empty := StyleBoxEmpty.new()
	th.set_stylebox("scroll", "VScrollBar", empty)
	th.set_stylebox("grabber", "VScrollBar", empty)
	th.set_stylebox("grabber_highlight", "VScrollBar", empty)
	th.set_stylebox("grabber_pressed", "VScrollBar", empty)
	return th


static func _box(bg: Color, radius: int, mx: int, my: int, shadow: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	s.shadow_color = Color(shadow, shadow.a * 0.55)
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 6)
	s.anti_aliasing = true
	return s


static func _button(th: Theme, type: String, bg: Color, fg: Color, radius: int, shadow: Color) -> void:
	var normal := _box(bg, radius, 28, 16, shadow)
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.06) if bg.v < 0.5 else bg.darkened(0.02)
	var pressed := normal.duplicate()
	pressed.bg_color = bg.darkened(0.08)
	pressed.shadow_offset = Vector2(0, 2)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(bg, 0.5)
	disabled.shadow_offset = Vector2.ZERO
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_corner_radius_all(radius + 4)
	focus.set_border_width_all(4)
	focus.border_color = Color(Game.COLORS.ink, 0.35)
	focus.expand_margin_left = 6
	focus.expand_margin_right = 6
	focus.expand_margin_top = 6
	focus.expand_margin_bottom = 6
	th.set_stylebox("normal", type, normal)
	th.set_stylebox("hover", type, hover)
	th.set_stylebox("pressed", type, pressed)
	th.set_stylebox("hover_pressed", type, pressed)
	th.set_stylebox("disabled", type, disabled)
	th.set_stylebox("focus", type, focus)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		th.set_color(k, type, fg)
	th.set_color("font_disabled_color", type, Color(fg, 0.45))
	th.set_color("icon_normal_color", type, Color.WHITE)
