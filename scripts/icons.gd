class_name Icons
extends RefCounted
## Ícones da interface. Vêm sempre de assets/images/<nome>.png.
## Enquanto a imagem não existir, mostra um texto curto no lugar.

const FONT := preload("res://assets/fonts/Baloo2-ExtraBold.ttf")

const FALLBACK := {
	"voltar": "<",
	"ajuda": "?",
	"desfazer": "<-",
	"limpar": "X",
	"dica": "!",
	"definicoes": "...",
}


static func has(name: String) -> bool:
	return Game.texture(name) != null


## Desenha uma textura centrada em `c` com `s` de lado.
static func draw_tex(ci: CanvasItem, tex: Texture2D, c: Vector2, s: float, mod := Color.WHITE) -> void:
	ci.draw_set_transform(c)
	ci.draw_texture_rect(tex, Rect2(-s * 0.5, -s * 0.5, s, s), false, mod)
	ci.draw_set_transform(Vector2.ZERO)


## Desenha o ícone `name` centrado em `c`, com `s` de lado.
## Se a imagem não existir, escreve o texto de FALLBACK com a cor `col`.
static func draw_icon(ci: CanvasItem, name: String, c: Vector2, s: float, col: Color) -> void:
	var tex := Game.texture(name)
	if tex:
		draw_tex(ci, tex, c, s, Color(1, 1, 1, col.a))
		return
	var txt: String = FALLBACK.get(name, "")
	if txt == "":
		return
	var fs := int(s * (0.78 if txt.length() == 1 else 0.5))
	var base := c.y + (FONT.get_ascent(fs) - FONT.get_descent(fs)) * 0.5
	ci.draw_string(FONT, Vector2(c.x - s, base), txt, HORIZONTAL_ALIGNMENT_CENTER, s * 2, fs, col)
