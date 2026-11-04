class_name UITheme
extends RefCounted
## Constrói o tema da interface (cores, fontes, botões, painéis).
## Variações de tipo: PrimaryButton, SoftButton, Card, RulesCard, Pill, Sheet,
## Title, H2, Muted, Small, PillLabel, ChipTitle.

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
	for v in [["Title", FONT_XBOLD, SIZE_TITLE, C.ink], ["H2", FONT_XBOLD, SIZE_H2, C.ink],
			["Muted", FONT_MEDIUM, SIZE_BODY, C.ink_soft], ["Small", FONT_MEDIUM, SIZE_SMALL, C.ink_soft],
			["PillLabel", FONT_XBOLD, SIZE_BODY, C.ink], ["ChipTitle", FONT_XBOLD, SIZE_SMALL + 2, C.ink]]:
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
	_button(th, "Button", C.snow, C.ink, 32, C.frost_dark)
	th.set_type_variation("PrimaryButton", "Button")
	_button(th, "PrimaryButton", C.ink, C.snow, 32, C.ink.darkened(0.45))
	th.set_type_variation("SoftButton", "Button")
	_button(th, "SoftButton", C.sky, C.ink, 32, Color(0, 0, 0, 0))
	for v in ["Button", "PrimaryButton", "SoftButton"]:
		th.set_font("font", v, FONT_XBOLD)
		th.set_font_size("font_size", v, SIZE_BODY + 2)
	th.set_constant("h_separation", "Button", 12)
	th.set_constant("icon_max_width", "Button", 44)
	# imagens opcionais (assets/images/ui_*.png) por cima do estilo desenhado
	_button_tex(th, "PrimaryButton", "ui_botao")
	_button_tex(th, "Button", "ui_botao_claro")
	_button_tex(th, "SoftButton", "ui_botao_claro")

	# Painéis
	th.set_stylebox("panel", "PanelContainer", _box(C.snow, 40, 32, 28, C.frost_dark))
	th.set_type_variation("Card", "PanelContainer")
	th.set_stylebox("panel", "Card", _box(C.snow, 40, 28, 24, C.frost_dark))
	th.set_type_variation("RulesCard", "PanelContainer")
	th.set_stylebox("panel", "RulesCard", _box(C.snow, 32, 12, 12, C.frost_dark))
	th.set_type_variation("Pill", "PanelContainer")
	th.set_stylebox("panel", "Pill", _box(C.snow, 40, 22, 6, C.frost_dark))
	for v in [["Card", 28, 24], ["RulesCard", 12, 12]]:
		var t := tex_box("ui_cartao", 52, v[1], v[2])
		if t:
			th.set_stylebox("panel", v[0], t)
	var pill := tex_box("ui_pilula", 30, 22, 6)
	if pill:
		th.set_stylebox("panel", "Pill", pill)
	th.set_type_variation("Sheet", "PanelContainer")
	var sheet := _box(C.snow, 48, 48, 28, Color(C.ink, 0.25))
	sheet.corner_radius_bottom_left = 0
	sheet.corner_radius_bottom_right = 0
	sheet.content_margin_bottom = 48
	sheet.shadow_offset = Vector2(0, -4)
	sheet.shadow_size = 16
	th.set_stylebox("panel", "Sheet", sheet)

	# Barra de progresso
	var track := StyleBoxFlat.new()
	track.bg_color = C.frost
	track.set_corner_radius_all(8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = C.ok
	fill.set_corner_radius_all(8)
	th.set_stylebox("background", "ProgressBar", track)
	th.set_stylebox("fill", "ProgressBar", fill)

	# Barra de scroll discreta
	var empty := StyleBoxEmpty.new()
	th.set_stylebox("scroll", "VScrollBar", empty)
	th.set_stylebox("grabber", "VScrollBar", empty)
	th.set_stylebox("grabber_highlight", "VScrollBar", empty)
	th.set_stylebox("grabber_pressed", "VScrollBar", empty)
	return th


## Caixa esticável feita a partir de assets/images/<name>.png (9-slice): os cantos
## (margin px) ficam iguais e o meio estica. null se a imagem não existir.
static func tex_box(name: String, margin: int, mx: int, my: int) -> StyleBoxTexture:
	var tex := Game.texture(name)
	if tex == null:
		return null
	var s := StyleBoxTexture.new()
	s.texture = tex
	var m := mini(margin, int(minf(tex.get_width(), tex.get_height()) * 0.45))
	s.texture_margin_left = m
	s.texture_margin_right = m
	s.texture_margin_top = m
	s.texture_margin_bottom = m
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	return s


static func _button_tex(th: Theme, type: String, name: String) -> void:
	var normal := tex_box(name, 48, 28, 16)
	if normal == null:
		return
	var hover: StyleBoxTexture = normal.duplicate()
	hover.modulate_color = Color(1.06, 1.06, 1.06)
	var pressed: StyleBoxTexture = normal.duplicate()
	pressed.modulate_color = Color(0.88, 0.88, 0.88)
	var disabled: StyleBoxTexture = normal.duplicate()
	disabled.modulate_color = Color(1, 1, 1, 0.5)
	th.set_stylebox("normal", type, normal)
	th.set_stylebox("hover", type, hover)
	th.set_stylebox("pressed", type, pressed)
	th.set_stylebox("hover_pressed", type, pressed)
	th.set_stylebox("disabled", type, disabled)


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
