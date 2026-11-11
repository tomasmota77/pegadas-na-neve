class_name AnimalBadge
extends Control
## Animal com a sua comida numa bolha no canto ("o ouriço quer o cogumelo").
## Usado nos cartões das regras por cima do tabuleiro.

var animal := "ourico":
	set(v):
		animal = v
		queue_redraw()


func _draw() -> void:
	var col: Color = Game.ANIMALS[animal].color
	var s := size.y
	var c := Vector2(size.x * 0.5 - s * 0.16, s * 0.5)
	var tex := Game.texture(animal)
	if tex:
		Icons.draw_tex(self, tex, c, s)
	# bolha com a comida, em baixo à direita
	var bc := c + Vector2(s * 0.54, s * 0.2)
	var br := s * 0.3
	draw_circle(bc + Vector2(0, 2), br, Color(col.darkened(0.3), 0.25), true, -1.0, true)
	draw_circle(bc, br, Game.COLORS.snow, true, -1.0, true)
	draw_arc(bc, br, 0.0, TAU, 40, col, maxf(2.0, s * 0.04), true)
	var food := Game.texture("comida_" + animal)
	if food:
		Icons.draw_tex(self, food, bc, br * 1.55)
